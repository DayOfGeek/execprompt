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
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/ollama_model.dart';
import '../models/pull_request.dart';

class OllamaApiService {
  final Dio _dio;
  CancelToken? _activeCancelToken;

  OllamaApiService({
    required String baseUrl,
    String? apiKey,
  })  : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: apiKey != null ? {'Authorization': 'Bearer $apiKey'} : {},
          connectTimeout: const Duration(seconds: 30),
          // No receiveTimeout for streaming — LLM responses can take minutes
          receiveTimeout: Duration.zero,
        ));

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  void updateApiKey(String? apiKey) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Stream chat completions from /api/chat
  Stream<ChatResponse> streamChat(ChatRequest request) async* {
    _activeCancelToken?.cancel('New request started');
    _activeCancelToken = CancelToken();
    final cancelToken = _activeCancelToken!;

    try {
      if (kDebugMode) {
        debugPrint('🌐 API: POST ${_dio.options.baseUrl}/api/chat');
      }

      // Build request body; inject think:true for thinking-capable models.
      // Ollama gracefully ignores this for non-thinking models.
      final body = request.toJson();
      body['think'] = true;

      final response = await _dio.post<ResponseBody>(
        '/api/chat',
        data: body,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      if (kDebugMode) {
        debugPrint('📥 Response status: ${response.statusCode}');
      }

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in stream) {
        if (cancelToken.isCancelled) break;
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          yield ChatResponse.fromJson(json);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Skipping malformed line: $e');
          }
          // Skip malformed lines
          continue;
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (kDebugMode) debugPrint('🛑 Stream cancelled by user');
        return;
      }
      if (kDebugMode) {
        debugPrint('❌ API Error: ${e.type} - ${e.message}');
        debugPrint('❌ Response: ${e.response?.data}');
      }
      throw _handleError(e);
    } finally {
      if (_activeCancelToken == cancelToken) {
        _activeCancelToken = null;
      }
    }
  }

  /// Cancel the active streaming request
  void cancelActiveRequest() {
    _activeCancelToken?.cancel('User stopped generation');
    _activeCancelToken = null;
  }

  /// List all local models from /api/tags
  Future<List<OllamaModel>> listModels() async {
    try {
      final response = await _dio.get('/api/tags');
      final modelsResponse = ModelsResponse.fromJson(response.data);
      return modelsResponse.models;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Pull a model from the Ollama library
  Stream<PullProgress> pullModel(String modelName) async* {
    try {
      final request = PullRequest(model: modelName);
      final response = await _dio.post<ResponseBody>(
        '/api/pull',
        data: request.toJson(),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.data == null) {
        throw Exception('No response data received');
      }

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in stream) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          yield PullProgress.fromJson(json);
        } catch (e) {
          continue;
        }
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a model
  Future<void> deleteModel(String modelName) async {
    try {
      await _dio.delete(
        '/api/delete',
        data: {'model': modelName},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Show model information
  Future<Map<String, dynamic>> showModel(String modelName) async {
    try {
      final response = await _dio.post(
        '/api/show',
        data: {'model': modelName},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate embeddings
  Future<List<List<double>>> generateEmbeddings({
    required String model,
    required dynamic input, // String or List<String>
  }) async {
    try {
      final response = await _dio.post(
        '/api/embed',
        data: {
          'model': model,
          'input': input,
        },
      );
      final embeddings = response.data['embeddings'] as List;
      return embeddings
          .map((e) => (e as List).map((v) => v as double).toList())
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get server version
  Future<String> getVersion() async {
    try {
      final response = await _dio.get('/api/version');
      return response.data['version'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your server URL.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server response timeout.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 404) {
        return 'Endpoint not found. Please check your Ollama server version.';
      } else if (statusCode == 401) {
        return 'Unauthorized. Please check your API key.';
      } else if (statusCode == 500) {
        return 'Server error. Please check your Ollama server logs.';
      }
      return 'HTTP Error $statusCode: ${e.response!.data}';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Network error. Please check your connection and server URL.';
    }
    return 'Unknown error: ${e.message}';
  }
}
