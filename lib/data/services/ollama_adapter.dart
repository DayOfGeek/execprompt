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


import '../models/chat_message.dart';
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/model_info.dart';
import 'api_adapter.dart';
import 'ollama_api_service.dart';

/// Adapter that wraps the existing [OllamaApiService] behind the
/// [ApiAdapter] contract.
///
/// This is a thin delegation layer — the real work is done by
/// [OllamaApiService], which remains untouched. Ollama native protocol
/// is the "home" format for ExecPrompt's internal models, so the
/// translation overhead here is minimal.
class OllamaAdapter extends ApiAdapter {
  final OllamaApiService _service;
  final String _endpointId;
  final String _endpointName;

  OllamaAdapter({
    required String baseUrl,
    required String endpointId,
    required String endpointName,
    String? apiKey,
  })  : _endpointId = endpointId,
        _endpointName = endpointName,
        _service = OllamaApiService(
          baseUrl: baseUrl,
          apiKey: apiKey,
        );

  /// Expose the underlying service for Ollama-specific operations
  /// (model pulling, deletion, show, embeddings) that don't belong
  /// on the generic [ApiAdapter] interface.
  OllamaApiService get ollamaService => _service;

  @override
  Stream<ChatResponse> streamChat(ChatRequest request) => _service.streamChat(request);

  @override
  Future<List<ModelInfo>> listModels() async {
    final models = await _service.listModels();
    return models
        .map((m) => ModelInfo(
              id: m.name,
              displayName: m.name,
              endpointId: _endpointId,
              endpointName: _endpointName,
              sizeBytes: m.size,
              family: m.details?.family,
              parameterSize: m.details?.parameterSize,
              quantizationLevel: m.details?.quantizationLevel,
            ))
        .toList();
  }

  @override
  void cancelActiveRequest() => _service.cancelActiveRequest();

  @override
  ChatMessage buildToolResultMessage({
    required String toolName,
    required String content,
    String? toolCallId,
  }) {
    // Ollama native uses tool_name, ignores tool_call_id.
    return ChatMessage(
      role: 'tool',
      content: content,
      toolName: toolName,
    );
  }

  @override
  void updateBaseUrl(String url) => _service.updateBaseUrl(url);

  @override
  void updateApiKey(String? key) => _service.updateApiKey(key);

  @override
  Future<String> testConnection() async {
    final version = await _service.getVersion();
    return 'Ollama v$version';
  }
}
