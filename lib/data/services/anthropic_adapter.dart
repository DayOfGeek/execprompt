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

/// Adapter for the Anthropic Messages API.
///
/// Wire format differences from OpenAI:
///   - Endpoint:    `POST /v1/messages`
///   - Auth:        `x-api-key` header (not Bearer token)
///   - System:      Top-level `system` field (not a system message)
///   - Streaming:   SSE with typed events (`message_start`, `content_block_delta`, etc.)
///   - Tool use:    `tool_use` / `tool_result` content blocks (not function calls)
///   - No models endpoint — we maintain a curated static list
///
/// Reference: https://docs.anthropic.com/en/api/messages
class AnthropicAdapter extends ApiAdapter {
  final Dio _dio;
  CancelToken? _activeCancelToken;
  final String _endpointId;
  final String _endpointName;

  /// The Anthropic API version header value.
  static const _anthropicVersion = '2023-06-01';

  AnthropicAdapter({
    required String baseUrl,
    required String endpointId,
    required String endpointName,
    String? apiKey,
  })  : _endpointId = endpointId,
        _endpointName = endpointName,
        _dio = Dio(BaseOptions(
          baseUrl: _normalizeBaseUrl(baseUrl),
          headers: {
            if (apiKey != null && apiKey.isNotEmpty) 'x-api-key': apiKey,
            'anthropic-version': _anthropicVersion,
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: Duration.zero,
        ));

  /// Normalize the base URL by stripping trailing `/v1` or `/v1/` segments.
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

  // ── ApiAdapter: streamChat ────────────────────────────────────────────

  @override
  Stream<ChatResponse> streamChat(ChatRequest request) async* {
    _activeCancelToken?.cancel('New request started');
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;

    try {
      final body = _buildRequestBody(request);
      if (kDebugMode) {
        debugPrint('🌐 Anthropic API: POST ${_dio.options.baseUrl}/v1/messages');
      }

      final response = await _dio.post<ResponseBody>(
        '/v1/messages',
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
      String? model;
      int? inputTokens;
      int? outputTokens;
      final toolUseBlocks = <_AnthropicToolUse>[];
      _AnthropicToolUse? currentToolUse;
      String? currentEventType;

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (cancelToken.isCancelled) break;
        if (line.isEmpty) continue;

        // SSE event type line
        if (line.startsWith('event: ')) {
          currentEventType = line.substring(7).trim();
          continue;
        }

        // SSE data line
        if (!line.startsWith('data: ')) continue;
        final payload = line.substring(6).trim();
        if (payload.isEmpty) continue;

        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;

          switch (currentEventType) {
            case 'message_start':
              final message = json['message'] as Map<String, dynamic>?;
              model = message?['model'] as String?;
              // Capture input token count from usage
              final startUsage = message?['usage'] as Map<String, dynamic>?;
              inputTokens = startUsage?['input_tokens'] as int? ?? inputTokens;
              break;

            case 'content_block_start':
              final contentBlock =
                  json['content_block'] as Map<String, dynamic>?;
              if (contentBlock != null) {
                final type = contentBlock['type'] as String?;
                if (type == 'tool_use') {
                  currentToolUse = _AnthropicToolUse(
                    id: contentBlock['id'] as String? ?? '',
                    name: contentBlock['name'] as String? ?? '',
                  );
                }
              }
              break;

            case 'content_block_delta':
              final delta = json['delta'] as Map<String, dynamic>?;
              String? deltaText;
              String? deltaThinking;
              if (delta != null) {
                final type = delta['type'] as String?;
                if (type == 'text_delta') {
                  deltaText = delta['text'] as String? ?? '';
                } else if (type == 'thinking_delta') {
                  deltaThinking = delta['thinking'] as String? ?? '';
                } else if (type == 'input_json_delta') {
                  // Tool use argument chunks
                  currentToolUse?.argumentsBuffer
                      .write(delta['partial_json'] as String? ?? '');
                }
              }

              // Emit intermediate chunk with delta-only content.
              // Chat provider appends each chunk to its own accumulator.
              if (deltaText != null || deltaThinking != null) {
                yield ChatResponse(
                  model: model ?? request.model,
                  createdAt: DateTime.now().toIso8601String(),
                  done: false,
                  message: ChatMessage(
                    role: 'assistant',
                    content: deltaText,
                    thinking: deltaThinking,
                  ),
                );
              }
              break;

            case 'content_block_stop':
              if (currentToolUse != null) {
                toolUseBlocks.add(currentToolUse);
                currentToolUse = null;
              }
              break;

            case 'message_delta':
              // Contains stop_reason. Content is null here — chat
              // provider has already accumulated all deltas.
              final delta = json['delta'] as Map<String, dynamic>?;
              final stopReason = delta?['stop_reason'] as String?;
              // Capture output token count from usage
              final deltaUsage = json['usage'] as Map<String, dynamic>?;
              outputTokens = deltaUsage?['output_tokens'] as int? ?? outputTokens;
              if (stopReason != null) {
                yield ChatResponse(
                  model: model ?? request.model,
                  createdAt: DateTime.now().toIso8601String(),
                  done: true,
                  doneReason: stopReason,
                  promptEvalCount: inputTokens,
                  evalCount: outputTokens,
                  message: ChatMessage(
                    role: 'assistant',
                    toolCalls: _resolveToolCalls(toolUseBlocks),
                  ),
                );
              }
              break;

            case 'message_stop':
              // Final event — if we haven't yielded done yet, do so now
              break;

            case 'error':
              final error = json['error'] as Map<String, dynamic>?;
              final msg = error?['message'] as String? ?? 'Unknown error';
              throw Exception('Anthropic error: $msg');

            default:
              // ping, etc. — ignore
              break;
          }
        } catch (e) {
          if (e is Exception &&
              e.toString().contains('Anthropic error')) {
            rethrow;
          }
          if (kDebugMode) debugPrint('⚠️ Anthropic: skipping malformed SSE chunk: $e');
          continue;
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (kDebugMode) debugPrint('🛑 Anthropic: stream cancelled by user');
        return;
      }
      // For streaming requests the error body is a ResponseBody that must
      // be read asynchronously to extract the actual error detail.
      String? streamErrorBody;
      if (e.response?.data is ResponseBody) {
        try {
          final body = e.response!.data as ResponseBody;
          final bytes = <int>[];
          await for (final chunk in body.stream) {
            bytes.addAll(chunk);
          }
          streamErrorBody = utf8.decode(bytes);
          if (kDebugMode) debugPrint('❌ Anthropic Error Body: $streamErrorBody');
        } catch (_) {}
      }
      if (kDebugMode) debugPrint('❌ Anthropic API Error: ${e.type} - ${e.message}');
      throw _handleError(e, streamErrorBody: streamErrorBody);
    } finally {
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  // ── ApiAdapter: listModels ────────────────────────────────────────────

  @override
  Future<List<ModelInfo>> listModels() async {
    // Try the Anthropic Models API first (GET /v1/models).
    // Falls back to a curated static list when the endpoint is
    // unavailable (e.g. older API versions or network issues).
    try {
      final response =
          await _dio.get('/v1/models', queryParameters: {'limit': 100});
      final data = response.data as Map<String, dynamic>;
      final models =
          (data['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (models.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
              '✅ Anthropic /v1/models returned ${models.length} models');
        }
        return models
            .map((m) => ModelInfo(
                  id: m['id'] as String? ?? 'unknown',
                  displayName: m['display_name'] as String? ??
                      m['id'] as String? ??
                      'unknown',
                  endpointId: _endpointId,
                  endpointName: _endpointName,
                  family: 'claude',
                ))
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'ℹ️ Anthropic /v1/models unavailable, using curated list: $e');
      }
    }

    // Fallback: curated static list
    return _curatedModels
        .map((m) => ModelInfo(
              id: m['id']!,
              displayName: m['name']!,
              endpointId: _endpointId,
              endpointName: _endpointName,
              contextLength: int.tryParse(m['context'] ?? ''),
              family: 'claude',
            ))
        .toList();
  }

  /// Curated Anthropic model list (updated as new models are released).
  static const _curatedModels = [
    {
      'id': 'claude-sonnet-4-20250514',
      'name': 'Claude Sonnet 4',
      'context': '200000'
    },
    {
      'id': 'claude-opus-4-20250514',
      'name': 'Claude Opus 4',
      'context': '200000'
    },
    {
      'id': 'claude-3-7-sonnet-20250219',
      'name': 'Claude 3.7 Sonnet',
      'context': '200000'
    },
    {
      'id': 'claude-3-5-haiku-20241022',
      'name': 'Claude 3.5 Haiku',
      'context': '200000'
    },
    {
      'id': 'claude-3-5-sonnet-20241022',
      'name': 'Claude 3.5 Sonnet',
      'context': '200000'
    },
    {
      'id': 'claude-3-opus-20240229',
      'name': 'Claude 3 Opus',
      'context': '200000'
    },
    {
      'id': 'claude-3-haiku-20240307',
      'name': 'Claude 3 Haiku',
      'context': '200000'
    },
  ];

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
    // For Anthropic, tool results are sent as a user message containing a
    // tool_result content block. We store toolCallId so the chat provider
    // can reconstruct the correct Anthropic format when sending.
    return ChatMessage(
      role: 'tool',
      content: content,
      toolCallId: toolCallId,
      toolName: toolName,
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
      _dio.options.headers['x-api-key'] = key;
    } else {
      _dio.options.headers.remove('x-api-key');
    }
  }

  // ── ApiAdapter: testConnection ────────────────────────────────────────

  @override
  Future<String> testConnection() async {
    // Anthropic doesn't have a lightweight health endpoint.
    // Send a minimal request to verify credentials.
    try {
      final response = await _dio.post(
        '/v1/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'hi'}
          ],
        },
      );
      final model = (response.data as Map<String, dynamic>)['model'] ?? '';
      return 'Anthropic API OK ($model)';
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw 'Unauthorized (401). Check your Anthropic API key.';
      }
      throw _handleError(e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────

  /// Build the Anthropic-format request body from our internal [ChatRequest].
  Map<String, dynamic> _buildRequestBody(ChatRequest request) {
    final body = <String, dynamic>{
      'model': request.model,
      'stream': request.stream,
      'max_tokens': _extractMaxTokens(request) ?? 8192,
    };

    if (request.messages != null) {
      // Extract system prompt from messages (Anthropic wants it top-level)
      final systemMessages =
          request.messages!.where((m) => m.role == 'system').toList();
      final nonSystemMessages =
          request.messages!.where((m) => m.role != 'system').toList();

      if (systemMessages.isNotEmpty) {
        body['system'] = systemMessages.map((m) => m.content).join('\n\n');
      }

      body['messages'] = _convertMessages(nonSystemMessages);
    }

    // Temperature
    if (request.options != null) {
      final opts = request.options!;
      if (opts.containsKey('temperature')) {
        body['temperature'] = opts['temperature'];
      }
      if (opts.containsKey('top_p')) body['top_p'] = opts['top_p'];
      // top_k is supported by Anthropic
      if (opts.containsKey('top_k')) body['top_k'] = opts['top_k'];
    }

    // Tools
    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!.map(_convertTool).toList();
    }

    // Extended thinking — enable for models that support it.
    // Claude 3.5 Sonnet and Claude 3.7+ models support extended thinking.
    // We enable it with a generous budget; the API will simply ignore it
    // for models that don't support thinking.
    final modelLower = request.model.toLowerCase();
    if (modelLower.contains('claude-3') &&
        (modelLower.contains('sonnet') ||
         modelLower.contains('opus') ||
         modelLower.contains('haiku'))) {
      // Auto-scale thinking budget: 50% of maxTokens, clamped to [1024, 32000].
      final maxTokens = body['max_tokens'] as int;
      final budget = (maxTokens * 0.5).toInt().clamp(1024, 32000);
      body['thinking'] = {
        'type': 'enabled',
        'budget_tokens': budget,
      };
      // Anthropic requires temperature == 1 when extended thinking is enabled.
      // Remove any user-supplied temperature to avoid a 400 error.
      body.remove('temperature');
    }

    return body;
  }

  /// Convert internal messages to Anthropic format.
  ///
  /// Key differences:
  /// - Images use `source.data` base64 blocks (not image_url)
  /// - Tool use messages become user messages with tool_result blocks
  /// - Consecutive same-role messages must be merged
  List<Map<String, dynamic>> _convertMessages(List<ChatMessage> messages) {
    final result = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg.role == 'tool') {
        // Tool results in Anthropic are sent as user messages
        result.add({
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': msg.toolCallId ?? 'tool_${msg.toolName}',
              'content': msg.content,
            },
          ],
        });
        continue;
      }

      if (msg.role == 'assistant' &&
          msg.toolCalls != null &&
          msg.toolCalls!.isNotEmpty) {
        // Assistant message with tool use
        final content = <Map<String, dynamic>>[];
        if (msg.content != null && msg.content!.isNotEmpty) {
          content.add({'type': 'text', 'text': msg.content});
        }
        for (final tc in msg.toolCalls!) {
          content.add({
            'type': 'tool_use',
            'id': tc.id ?? 'tool_${tc.function_.name}',
            'name': tc.function_.name,
            'input': tc.function_.arguments,
          });
        }
        result.add({'role': 'assistant', 'content': content});
        continue;
      }

      // Regular user/assistant message
      if (msg.images != null && msg.images!.isNotEmpty && msg.role == 'user') {
        // Multimodal user message
        final content = <Map<String, dynamic>>[];
        if (msg.content != null) {
          content.add({'type': 'text', 'text': msg.content});
        }
        for (final img in msg.images!) {
          content.add({
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/jpeg',
              'data': img,
            },
          });
        }
        result.add({'role': msg.role, 'content': content});
      } else {
        result.add({
          'role': msg.role,
          'content': msg.content ?? '',
        });
      }
    }

    // Anthropic requires alternating user/assistant roles.
    // Merge consecutive same-role messages.
    return _mergeConsecutiveRoles(result);
  }

  /// Merge consecutive messages with the same role (Anthropic requirement).
  List<Map<String, dynamic>> _mergeConsecutiveRoles(
    List<Map<String, dynamic>> messages,
  ) {
    if (messages.length <= 1) return messages;

    final merged = <Map<String, dynamic>>[];
    for (final msg in messages) {
      if (merged.isNotEmpty && merged.last['role'] == msg['role']) {
        // Merge content
        final existingContent = merged.last['content'];
        final newContent = msg['content'];
        if (existingContent is String && newContent is String) {
          merged.last['content'] = '$existingContent\n\n$newContent';
        } else {
          // Convert to list content blocks and merge
          final existing = existingContent is List
              ? List<Map<String, dynamic>>.from(existingContent)
              : [
                  {'type': 'text', 'text': existingContent.toString()}
                ];
          final incoming = newContent is List
              ? List<Map<String, dynamic>>.from(newContent)
              : [
                  {'type': 'text', 'text': newContent.toString()}
                ];
          merged.last['content'] = [...existing, ...incoming];
        }
      } else {
        merged.add(Map<String, dynamic>.from(msg));
      }
    }
    return merged;
  }

  /// Convert our standard tool JSON to Anthropic's tool format.
  ///
  /// Ours/OpenAI: `{type: "function", function: {name, description, parameters}}`
  /// Anthropic:   `{name, description, input_schema}`
  Map<String, dynamic> _convertTool(Map<String, dynamic> tool) {
    final fn = tool['function'] as Map<String, dynamic>? ?? tool;
    return {
      'name': fn['name'],
      'description': fn['description'],
      'input_schema': fn['parameters'] ?? {'type': 'object', 'properties': {}},
    };
  }

  /// Extract max_tokens from request options (Anthropic requires it).
  int? _extractMaxTokens(ChatRequest request) {
    if (request.options == null) return null;
    return request.options!['num_predict'] as int?;
  }

  /// Resolve accumulated tool use blocks into [ToolCallWrapper] list.
  List<ToolCallWrapper>? _resolveToolCalls(List<_AnthropicToolUse> blocks) {
    if (blocks.isEmpty) return null;

    return blocks.map((block) {
      Map<String, dynamic> args;
      try {
        final raw = block.argumentsBuffer.toString();
        args = raw.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        args = {'raw': block.argumentsBuffer.toString()};
      }

      return ToolCallWrapper(
        id: block.id,
        function_: ToolCallFunction(
          name: block.name,
          arguments: args,
        ),
      );
    }).toList();
  }

  String _handleError(DioException e, {String? streamErrorBody}) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Check the Anthropic endpoint URL.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      String? detail;
      if (data is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>?;
        detail = error?['message'] as String?;
      } else if (streamErrorBody != null) {
        try {
          final json = jsonDecode(streamErrorBody) as Map<String, dynamic>;
          final error = json['error'] as Map<String, dynamic>?;
          detail = error?['message'] as String?;
        } catch (_) {
          detail = streamErrorBody;
        }
      }
      if (statusCode == 401) {
        return 'Unauthorized (401). Check your Anthropic API key.${detail != null ? ' $detail' : ''}';
      } else if (statusCode == 429) {
        return 'Rate limited (429). ${detail ?? 'Try again later.'}';
      } else if (statusCode == 400) {
        return 'Bad request (400). ${detail ?? 'Check model name and message format.'}';
      } else if (statusCode == 529) {
        return 'Anthropic overloaded (529). Try again in a moment.';
      }
      return 'HTTP $statusCode: ${detail ?? data}';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Network error. Check your connection.';
    }
    return 'Error: ${e.message}';
  }
}

/// Accumulates streaming tool_use content blocks.
class _AnthropicToolUse {
  final String id;
  final String name;
  final StringBuffer argumentsBuffer = StringBuffer();

  _AnthropicToolUse({required this.id, required this.name});
}
