// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/model_info.dart';
import 'api_adapter.dart';

/// Adapter for OpenAI-compatible APIs (OpenAI, OpenRouter, Ollama /v1,
/// Together, Groq, etc.).
///
/// Wire format:
///   - Streaming: SSE (`data: {...}\n\n`)
///   - Chat:      `POST /v1/chat/completions`
///   - Models:    `GET  /v1/models`
///
/// Tool calls use `tool_call_id` for correlation (vs Ollama's `tool_name`).
/// Arguments arrive as chunked strings that must be accumulated.
class OpenAiAdapter extends ApiAdapter {
  final Dio _dio;
  CancelToken? _activeCancelToken;
  final String _endpointId;
  final String _endpointName;

  OpenAiAdapter({
    required String baseUrl,
    required String endpointId,
    required String endpointName,
    String? apiKey,
    Map<String, String>? extraHeaders,
  })  : _endpointId = endpointId,
        _endpointName = endpointName,
        _dio = Dio(BaseOptions(
          baseUrl: _normalizeBaseUrl(baseUrl),
          headers: {
            if (apiKey != null && apiKey.isNotEmpty)
              'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            ...?extraHeaders,
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: Duration.zero, // streaming can take minutes
        ));

  /// Normalize the base URL by stripping trailing `/v1` or `/v1/` segments.
  /// This allows users to enter either `https://openrouter.ai/api` or
  /// `https://openrouter.ai/api/v1` — both resolve correctly since the
  /// adapter always appends `/v1/chat/completions`, `/v1/models`, etc.
  static String _normalizeBaseUrl(String url) {
    var normalized = url.trimRight();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.endsWith('/v1')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }

  /// Whether this adapter points at a Gemini endpoint.
  bool get _isGemini =>
      _dio.options.baseUrl.contains('generativelanguage.googleapis.com');

  // ── ApiAdapter: streamChat ────────────────────────────────────────────

  @override
  Stream<ChatResponse> streamChat(ChatRequest request) async* {
    // Gemini requires thought_signatures on tool-call round-trips, but the
    // OpenAI-compatible streaming format does NOT include them in SSE deltas.
    // Use a non-streaming request when tools are present so we get the full
    // response with thought_signatures.  The follow-up request (with tool
    // results) streams normally since tools are already null.
    if (_isGemini &&
        request.tools != null &&
        request.tools!.isNotEmpty) {
      yield* _geminiNonStreamingToolCall(request);
      return;
    }

    _activeCancelToken?.cancel('New request started');
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;

    try {
      final body = _buildRequestBody(request);
      if (kDebugMode) {
        debugPrint('🌐 OpenAI API: POST ${_dio.options.baseUrl}/v1/chat/completions');
      }

      final response = await _dio.post<ResponseBody>(
        '/v1/chat/completions',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
        cancelToken: cancelToken,
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      // SSE parsing state
      final toolCallMap = <int, _ToolCallAccumulator>{};
      String? model;
      int? inputTokens;
      int? outputTokens;

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (cancelToken.isCancelled) break;

        // SSE lines: "data: {...}" or "data: [DONE]"
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload == '[DONE]') {
          // Emit final done response. Content is null here — the chat
          // provider has already accumulated all deltas itself.
          yield ChatResponse(
            model: model ?? request.model,
            createdAt: DateTime.now().toIso8601String(),
            done: true,
            doneReason: 'stop',
            promptEvalCount: inputTokens,
            evalCount: outputTokens,
            message: ChatMessage(
              role: 'assistant',
              toolCalls: _resolveToolCalls(toolCallMap),
            ),
          );
          return;
        }

        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          model = json['model'] as String? ?? model;

          // Capture usage data (present in final chunk for some providers)
          final usage = json['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            inputTokens = usage['prompt_tokens'] as int? ?? inputTokens;
            outputTokens = usage['completion_tokens'] as int? ?? outputTokens;
          }

          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;

          final choice = choices[0] as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>? ?? {};
          final finishReason = choice['finish_reason'] as String?;

          // Content token
          final content = delta['content'] as String?;

          // Thinking / reasoning content (provider-specific field names)
          // - Ollama /v1: 'thinking'
          // - DeepSeek: 'reasoning_content'
          // - OpenRouter: 'reasoning'
          // - Other providers: 'thought'
          final thinking = delta['thinking'] as String? ??
              delta['reasoning'] as String? ??
              delta['reasoning_content'] as String? ??
              delta['thought'] as String?;

          // Tool calls (streamed as incremental chunks)
          final deltaToolCalls = delta['tool_calls'] as List<dynamic>?;
          if (deltaToolCalls != null) {
            for (final tc in deltaToolCalls) {
              final tcMap = tc as Map<String, dynamic>;
              final index = tcMap['index'] as int? ?? 0;
              final id = tcMap['id'] as String?;
              final fn = tcMap['function'] as Map<String, dynamic>?;

              // Log the raw delta for tool-call debugging
              if (id != null && kDebugMode) {
                debugPrint('🔍 SSE tool_call delta idx=$index '
                    'keys=${tcMap.keys.toList()}');
              }

              toolCallMap.putIfAbsent(
                  index, () => _ToolCallAccumulator(id: id));

              if (id != null) toolCallMap[index]!.id ??= id;
              // Gemini: capture thought_signature for tool call round-trips
              final thoughtSig = tcMap['thought_signature'] as String?;
              if (thoughtSig != null) {
                toolCallMap[index]!.thoughtSignature = thoughtSig;
              }
              if (fn != null) {
                if (fn['name'] != null) {
                  toolCallMap[index]!.name = fn['name'] as String;
                }
                if (fn['arguments'] != null) {
                  toolCallMap[index]!.argumentsBuffer
                      .write(fn['arguments'] as String);
                }
              }
            }
          }

          // Emit intermediate chunks for streaming UI.
          // IMPORTANT: yield only the *delta* content/thinking, not the
          // full accumulation, because the chat provider appends each
          // chunk to its own accumulator.
          if (finishReason == null) {
            yield ChatResponse(
              model: model ?? request.model,
              createdAt: DateTime.now().toIso8601String(),
              done: false,
              message: ChatMessage(
                role: 'assistant',
                content: content,   // delta only
                thinking: thinking, // delta only
              ),
            );
          } else {
            // finish_reason present → final chunk; return to avoid
            // duplicate done from the subsequent [DONE] sentinel.
            // Content is null here — chat provider already accumulated
            // all deltas.
            yield ChatResponse(
              model: model ?? request.model,
              createdAt: DateTime.now().toIso8601String(),
              done: true,
              doneReason: finishReason,
              promptEvalCount: inputTokens,
              evalCount: outputTokens,
              message: ChatMessage(
                role: 'assistant',
                toolCalls: _resolveToolCalls(toolCallMap),
              ),
            );
            return; // ← exit generator; [DONE] is redundant after this
          }
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ OpenAI: skipping malformed SSE chunk: $e');
          continue;
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (kDebugMode) debugPrint('🛑 OpenAI: stream cancelled by user');
        return;
      }
      // For streaming requests the error body is a ResponseBody that must
      // be read asynchronously before we can extract the error detail.
      String? streamErrorBody;
      if (e.response?.data is ResponseBody) {
        try {
          final body = e.response!.data as ResponseBody;
          final bytes = <int>[];
          await for (final chunk in body.stream) {
            bytes.addAll(chunk);
          }
          streamErrorBody = utf8.decode(bytes);
          if (kDebugMode) debugPrint('❌ OpenAI Error Body: $streamErrorBody');
        } catch (_) {}
      }
      if (kDebugMode) debugPrint('❌ OpenAI API Error: ${e.type} - ${e.message}');
      throw _handleError(e, streamErrorBody: streamErrorBody);
    } finally {
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  // ── Gemini: non-streaming tool-call path ──────────────────────────────

  /// Gemini requires `thought_signature` on every tool-call round-trip but
  /// only includes it in the full (non-streaming) JSON response.  This
  /// method performs a single non-streaming POST, parses the result, and
  /// yields it as a [ChatResponse] so the rest of the pipeline is unchanged.
  Stream<ChatResponse> _geminiNonStreamingToolCall(
      ChatRequest request) async* {
    _activeCancelToken?.cancel('New request started');
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;

    try {
      final body = _buildRequestBody(request);
      body['stream'] = false; // override to non-streaming
      if (kDebugMode) {
        debugPrint(
            '🌐 OpenAI API (non-stream/Gemini tools): '
            'POST ${_dio.options.baseUrl}/v1/chat/completions');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/chat/completions',
        data: body,
        options: Options(responseType: ResponseType.json),
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null) throw Exception('No response data received');

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Empty choices in Gemini response');
      }

      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>;
      final content = message['content'] as String?;
      final model = data['model'] as String?;
      final finishReason = choice['finish_reason'] as String? ?? 'stop';

      // Capture usage from Gemini response
      final usage = data['usage'] as Map<String, dynamic>?;
      final gmInputTokens = usage?['prompt_tokens'] as int?;
      final gmOutputTokens = usage?['completion_tokens'] as int?;

      // Extract thinking/reasoning from the full response
      final thinking = message['thinking'] as String? ??
          message['reasoning'] as String? ??
          message['reasoning_content'] as String? ??
          message['thought'] as String?;

      // Parse tool_calls with thought_signatures
      List<ToolCallWrapper>? toolCalls;
      final rawToolCalls = message['tool_calls'] as List<dynamic>?;
      if (rawToolCalls != null && rawToolCalls.isNotEmpty) {
        toolCalls = rawToolCalls.map((tc) {
          final tcMap = tc as Map<String, dynamic>;
          final fn = tcMap['function'] as Map<String, dynamic>;
          final thoughtSig = tcMap['thought_signature'] as String?;

          if (kDebugMode) {
            debugPrint(
                '🔍 Gemini tool call: ${fn['name']} '
                'thoughtSig=${thoughtSig != null ? '${thoughtSig.length} chars' : 'null'}');
          }

          Map<String, dynamic> args;
          try {
            args = jsonDecode(fn['arguments'] as String)
                as Map<String, dynamic>;
          } catch (_) {
            args = {'raw': fn['arguments']};
          }

          return ToolCallWrapper(
            id: tcMap['id'] as String?,
            thoughtSignature: thoughtSig,
            function_: ToolCallFunction(
              name: fn['name'] as String,
              arguments: args,
            ),
          );
        }).toList();
      }

      yield ChatResponse(
        model: model ?? request.model,
        createdAt: DateTime.now().toIso8601String(),
        done: true,
        doneReason: finishReason,
        promptEvalCount: gmInputTokens,
        evalCount: gmOutputTokens,
        message: ChatMessage(
          role: 'assistant',
          content: content,
          thinking: thinking,
          toolCalls: toolCalls,
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (kDebugMode) debugPrint('🛑 Gemini non-streaming: cancelled by user');
        return;
      }
      final detail = e.response?.data is Map
          ? jsonEncode(e.response!.data)
          : e.response?.data?.toString();
      if (kDebugMode) debugPrint('❌ Gemini non-streaming error: $detail');
      throw _handleError(e, streamErrorBody: detail);
    } finally {
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  // ── ApiAdapter: listModels ────────────────────────────────────────────

  @override
  Future<List<ModelInfo>> listModels() async {
    try {
      final response = await _dio.get('/v1/models');
      final data = response.data as Map<String, dynamic>;
      final models = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      return models.map((m) {
        return ModelInfo(
          id: m['id'] as String? ?? 'unknown',
          displayName: m['id'] as String? ?? 'unknown',
          endpointId: _endpointId,
          endpointName: _endpointName,
          // OpenAI-spec doesn't consistently expose size, context, etc.
          // Some providers add custom fields — extract what's available.
          contextLength: m['context_length'] as int?,
        );
      }).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── ApiAdapter: cancelActiveRequest ───────────────────────────────────

  @override
  void cancelActiveRequest() {
    _activeCancelToken?.cancel('User stopped generation');
    _activeCancelToken = null;
  }

  // ── ApiAdapter: buildToolResultMessage ────────────────────────────────

  @override
  ChatMessage buildToolResultMessage({
    required String toolName,
    required String content,
    String? toolCallId,
  }) {
    // OpenAI spec requires tool_call_id, not tool_name.
    return ChatMessage(
      role: 'tool',
      content: content,
      toolCallId: toolCallId,
    );
  }

  // ── ApiAdapter: updateBaseUrl / updateApiKey ──────────────────────────

  @override
  void updateBaseUrl(String url) {
    _dio.options.baseUrl = _normalizeBaseUrl(url);
  }

  @override
  void updateApiKey(String? key) {
    if (key != null && key.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $key';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // ── ApiAdapter: testConnection ────────────────────────────────────────

  @override
  Future<String> testConnection() async {
    try {
      final models = await listModels();
      return 'OK — ${models.length} models available';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Build the OpenAI-format request body from our internal [ChatRequest].
  Map<String, dynamic> _buildRequestBody(ChatRequest request) {
    final body = <String, dynamic>{
      'model': request.model,
      'stream': request.stream,
    };

    // Messages — convert from internal format to OpenAI format
    if (request.messages != null) {
      body['messages'] = request.messages!.map(_convertMessage).toList();
    }

    // Options → OpenAI parameter names
    if (request.options != null) {
      final opts = request.options!;
      if (opts.containsKey('temperature')) {
        body['temperature'] = opts['temperature'];
      }
      if (opts.containsKey('top_p')) body['top_p'] = opts['top_p'];
      if (opts.containsKey('num_predict')) {
        body['max_tokens'] = opts['num_predict'];
      }
      if (opts.containsKey('repeat_penalty')) {
        body['frequency_penalty'] = _convertRepeatPenalty(
          opts['repeat_penalty'] as double? ?? 1.1,
        );
      }
      // top_k is not part of OpenAI spec — skip it.
    }

    // Tools
    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools;
    }

    return body;
  }

  /// Convert internal [ChatMessage] to OpenAI wire format.
  Map<String, dynamic> _convertMessage(ChatMessage msg) {
    final result = <String, dynamic>{'role': msg.role};

    // Handle multimodal content (images)
    if (msg.images != null && msg.images!.isNotEmpty && msg.role == 'user') {
      result['content'] = [
        if (msg.content != null)
          {'type': 'text', 'text': msg.content},
        ...msg.images!.map((img) => {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$img'},
            }),
      ];
    } else {
      result['content'] = msg.content;
    }

    // Tool calls (assistant → model is calling tools)
    if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
      result['tool_calls'] = msg.toolCalls!.map((tc) {
        final args = tc.function_.arguments;
        final entry = <String, dynamic>{
          'id': tc.id ?? 'call_${tc.function_.name}',
          'type': 'function',
          'function': {
            'name': tc.function_.name,
            'arguments':
                args is String ? args : jsonEncode(args),
          },
        };
        // Gemini: echo thought_signature back for tool result round-trips
        if (tc.thoughtSignature != null) {
          entry['thought_signature'] = tc.thoughtSignature;
        }
        return entry;
      }).toList();
      // OpenAI doesn't want content alongside tool_calls (some providers reject it)
      if (msg.content == null || msg.content!.isEmpty) {
        result.remove('content');
      }
    }

    // Tool result messages
    if (msg.role == 'tool') {
      result['tool_call_id'] = msg.toolCallId ?? 'call_${msg.toolName}';
      result.remove('content');
      result['content'] = msg.content;
    }

    return result;
  }

  /// Convert Ollama's repeat_penalty (1.0 = neutral, >1 = penalize) to
  /// OpenAI's frequency_penalty (-2.0 to 2.0, 0 = neutral).
  double _convertRepeatPenalty(double repeatPenalty) {
    // Rough mapping: repeat_penalty 1.0 → 0.0, 1.5 → 1.0, 2.0 → 2.0
    return (repeatPenalty - 1.0) * 2.0;
  }

  /// Resolve accumulated tool call chunks into [ToolCallWrapper] list.
  List<ToolCallWrapper>? _resolveToolCalls(
    Map<int, _ToolCallAccumulator> accumulators,
  ) {
    if (accumulators.isEmpty) return null;

    final resolved = <ToolCallWrapper>[];
    for (final entry in accumulators.entries) {
      final acc = entry.value;
      if (acc.name == null) continue; // incomplete tool call — skip

      Map<String, dynamic> args;
      try {
        args = jsonDecode(acc.argumentsBuffer.toString())
            as Map<String, dynamic>;
      } catch (_) {
        // If JSON parsing fails, wrap the raw string
        args = {'raw': acc.argumentsBuffer.toString()};
      }

      resolved.add(ToolCallWrapper(
        id: acc.id,
        thoughtSignature: acc.thoughtSignature,
        function_: ToolCallFunction(
          name: acc.name!,
          arguments: args,
        ),
      ));
    }

    return resolved.isNotEmpty ? resolved : null;
  }

  String _handleError(DioException e, {String? streamErrorBody}) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Check the endpoint URL.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      // Try to extract the provider's error message.
      // For streaming requests data may be a ResponseBody — use the
      // pre-read streamErrorBody instead.
      String? detail;
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          detail = error['message'] as String?;
        } else if (error is String) {
          detail = error;
        }
      } else if (streamErrorBody != null) {
        try {
          final json = jsonDecode(streamErrorBody) as Map<String, dynamic>;
          final error = json['error'];
          if (error is Map<String, dynamic>) {
            detail = error['message'] as String?;
          } else if (error is String) {
            detail = error;
          }
        } catch (_) {
          detail = streamErrorBody;
        }
      }
      if (statusCode == 401) {
        return 'Unauthorized (401). Check your API key.${detail != null ? ' $detail' : ''}';
      } else if (statusCode == 429) {
        return 'Rate limited (429). ${detail ?? 'Try again later.'}'; 
      } else if (statusCode == 404) {
        return 'Not found (404). Check your endpoint URL and model name.';
      }
      return 'HTTP $statusCode: ${detail ?? data}';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Network error. Check your connection and endpoint URL.';
    }
    return 'Error: ${e.message}';
  }
}

/// Accumulates streaming tool call chunks (index-based).
class _ToolCallAccumulator {
  String? id;
  String? name;
  String? thoughtSignature;
  final StringBuffer argumentsBuffer = StringBuffer();

  _ToolCallAccumulator({this.id});
}
