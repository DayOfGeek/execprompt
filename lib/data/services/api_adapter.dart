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

/// Abstract contract for all AI provider adapters.
///
/// Each [ApiAdapter] implementation translates between ExecPrompt's internal
/// data models and a specific provider's wire format. The [ChatProvider]
/// (orchestrator) only interacts through this interface — it never knows
/// which provider is behind the adapter.
///
/// ## Implementing a new adapter
///
/// 1. Create a class extending [ApiAdapter].
/// 2. Add a new value to [EndpointType].
/// 3. Register the factory in [ApiServiceRouter].
///
/// That's it — no existing adapter code needs to change.
///
/// ## Current implementations
///
/// | Adapter            | Protocol           | Streaming format |
/// |--------------------|--------------------|------------------|
/// | `OllamaAdapter`    | Ollama native API  | NDJSON           |
/// | `OpenAiAdapter`    | OpenAI v1 API      | SSE              |
/// | `AnthropicAdapter` | Anthropic Messages | SSE              |
abstract class ApiAdapter {
  /// Stream a chat completion, yielding normalized [ChatResponse] chunks.
  ///
  /// The adapter translates [request] into the provider's wire format,
  /// sends it, and converts each streaming chunk back into our internal
  /// [ChatResponse] model. The caller sees a uniform stream regardless
  /// of whether the underlying transport is NDJSON, SSE, or something else.
  ///
  /// The stream completes when the provider signals "done" or the request
  /// is cancelled via [cancelActiveRequest].
  Stream<ChatResponse> streamChat(ChatRequest request);

  /// List available models for this endpoint, normalized to [ModelInfo].
  ///
  /// - Ollama: fetches from `/api/tags`
  /// - OpenAI: fetches from `/v1/models`
  /// - Anthropic: returns a curated static list (no discovery endpoint)
  Future<List<ModelInfo>> listModels();

  /// Cancel the currently active streaming request, if any.
  ///
  /// This is a no-op if no request is in flight. Safe to call from any
  /// isolate or callback.
  void cancelActiveRequest();

  /// Build a tool-result message in the format this provider expects.
  ///
  /// - Ollama native: `{role: "tool", content: "...", tool_name: "web_search"}`
  /// - OpenAI:        `{role: "tool", content: "...", tool_call_id: "call_123"}`
  /// - Anthropic:     content block `{type: "tool_result", tool_use_id: "toolu_xxx", content: "..."}`
  ///
  /// The [toolCallId] is required for OpenAI/Anthropic and null for Ollama.
  ChatMessage buildToolResultMessage({
    required String toolName,
    required String content,
    String? toolCallId,
  });

  /// Update the base URL at runtime (e.g. user changed it in settings).
  void updateBaseUrl(String url);

  /// Update the API key at runtime (e.g. user changed it in settings).
  void updateApiKey(String? key);

  /// Test the connection to this endpoint.
  ///
  /// Returns a human-readable status string on success (e.g. "Ollama v0.5.7",
  /// "OpenAI API OK") or throws on failure.
  Future<String> testConnection();
}
