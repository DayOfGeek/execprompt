// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'endpoint.freezed.dart';
part 'endpoint.g.dart';

/// The type of API a given endpoint speaks.
///
/// Each value maps to a dedicated [ApiAdapter] implementation:
///   - [ollama]    → OllamaAdapter  (NDJSON streaming, /api/chat)
///   - [openai]    → OpenAiAdapter   (SSE streaming, /v1/chat/completions)
///   - [anthropic] → AnthropicAdapter(SSE streaming, /v1/messages)
///
/// Adding a new provider = new enum value + new adapter class.
enum EndpointType {
  @JsonValue('ollama')
  ollama,
  @JsonValue('openai')
  openai,
  @JsonValue('anthropic')
  anthropic,
}

/// A named API endpoint that the user has configured.
///
/// Each endpoint represents a connection to a specific AI provider instance
/// (e.g. "Ollama Cloud", "My Local Ollama", "OpenRouter", "Anthropic Direct").
///
/// The [selectedModels] list contains the model IDs that the user has curated
/// for this endpoint. Only these models appear in the model picker.
/// At least one model must be selected per endpoint.
///
/// API keys are stored separately in flutter_secure_storage, keyed by
/// `endpoint_apikey_{id}`. The [apiKey] field here is transient (never
/// persisted to SharedPreferences JSON).
@freezed
class Endpoint with _$Endpoint {
  const Endpoint._();

  const factory Endpoint({
    /// Unique identifier (UUID v4).
    required String id,

    /// User-friendly display name (e.g. "Ollama Cloud", "OpenRouter").
    required String name,

    /// Base URL for API requests (e.g. "https://ollama.com", "https://openrouter.ai/api").
    required String baseUrl,

    /// Which API protocol this endpoint speaks.
    required EndpointType type,

    /// Model IDs curated by the user for this endpoint.
    /// Only these appear in the model picker.
    @Default([]) List<String> selectedModels,

    /// Display order in the UI (lower = higher).
    @Default(0) int sortOrder,

    /// Whether this endpoint is active (shown in the model picker).
    @Default(true) bool isActive,

    /// When this endpoint was created.
    required DateTime createdAt,

    /// When this endpoint was last modified.
    required DateTime updatedAt,

    /// Transient API key — loaded from secure storage at runtime,
    /// NOT serialized to the SharedPreferences JSON blob.
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? apiKey,
  }) = _Endpoint;

  /// Redact apiKey from toString to prevent leaking secrets in logs/traces.
  @override
  String toString() =>
      'Endpoint(id: $id, name: $name, baseUrl: $baseUrl, type: $type, '
      'models: ${selectedModels.length}, apiKey: ${apiKey != null ? "[REDACTED]" : "null"})';

  factory Endpoint.fromJson(Map<String, dynamic> json) =>
      _$EndpointFromJson(json);
}
