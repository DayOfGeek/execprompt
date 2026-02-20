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


import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';

part 'ollama_error.freezed.dart';

@freezed
class OllamaError with _$OllamaError {
  const factory OllamaError.network({
    required String message,
    @Default(true) bool canRetry,
    Object? originalError,
  }) = NetworkError;

  const factory OllamaError.modelNotFound({
    required String modelName,
  }) = ModelNotFoundError;

  const factory OllamaError.authentication({
    required String message,
  }) = AuthenticationError;

  const factory OllamaError.server({
    required int statusCode,
    required String message,
  }) = ServerError;

  const factory OllamaError.timeout({
    required String message,
    @Default(true) bool canRetry,
  }) = TimeoutError;

  const factory OllamaError.unknown({
    required String message,
    @Default(false) bool canRetry,
    Object? originalError,
  }) = UnknownError;

  /// Create OllamaError from DioException
  factory OllamaError.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const OllamaError.timeout(
          message: 'Request timed out. Please check your connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?.toString() ?? 'Unknown server error';
        
        if (statusCode == 404) {
          // Try to extract model name from request
          return const OllamaError.modelNotFound(
            modelName: 'requested model',
          );
        } else if (statusCode == 401 || statusCode == 403) {
          return const OllamaError.authentication(
            message: 'Authentication failed. Check your API key.',
          );
        } else {
          return OllamaError.server(
            statusCode: statusCode,
            message: message,
          );
        }

      case DioExceptionType.connectionError:
        return OllamaError.network(
          message: 'Cannot connect to server. Check the URL and your network.',
          originalError: e.error,
        );

      case DioExceptionType.cancel:
        return const OllamaError.unknown(
          message: 'Request was cancelled',
          canRetry: false,
        );

      case DioExceptionType.badCertificate:
        return OllamaError.network(
          message: 'SSL certificate error. The server certificate is not trusted.',
          canRetry: false,
          originalError: e.error,
        );

      case DioExceptionType.unknown:
        return OllamaError.unknown(
          message: e.message ?? 'An unknown error occurred',
          originalError: e.error,
        );
    }
  }
}

extension OllamaErrorExtension on OllamaError {
  /// Get user-friendly error message
  String get userMessage => when(
    network: (message, canRetry, _) => message,
    modelNotFound: (modelName) => 'Model "$modelName" not found. Please pull it first or select a different model.',
    authentication: (message) => message,
    server: (statusCode, message) => 'Server error ($statusCode): $message',
    timeout: (message, _) => message,
    unknown: (message, _, __) => message,
  );

  /// Whether this error can be retried
  bool get canRetry => when(
    network: (_, canRetry, __) => canRetry,
    modelNotFound: (_) => false,
    authentication: (_) => false,
    server: (statusCode, _) => statusCode >= 500,
    timeout: (_, canRetry) => canRetry,
    unknown: (_, canRetry, __) => canRetry,
  );

  /// Get icon for this error type
  String get icon => when(
    network: (_, __, ___) => '🌐',
    modelNotFound: (_) => '🤖',
    authentication: (_) => '🔒',
    server: (_, __) => '⚠️',
    timeout: (_, __) => '⏱️',
    unknown: (_, __, ___) => '❌',
  );
}
