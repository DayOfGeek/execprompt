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

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Provider-agnostic model information.
///
/// This is the normalized representation used throughout the UI.
/// Each [ApiAdapter] converts its provider-specific model data into this
/// common format.
///
/// The [qualifiedId] is `{endpointId}:{modelId}` and uniquely identifies a
/// model across all endpoints (avoids collisions when the same model name
/// exists on multiple endpoints, e.g. two Ollama instances both running
/// `llama3.2`).
@freezed
class ModelInfo with _$ModelInfo {
  const ModelInfo._();

  const factory ModelInfo({
    /// The model identifier as the provider knows it (e.g. "deepseek-r1:14b",
    /// "anthropic/claude-3.5-sonnet").
    required String id,

    /// Human-friendly display name. Often the same as [id] but can be cleaned
    /// up (e.g. strip org prefix for Anthropic).
    required String displayName,

    /// The endpoint ID this model belongs to.
    required String endpointId,

    /// The endpoint's display name (for grouping in the picker).
    required String endpointName,

    /// Model size in bytes (available for Ollama, null for others).
    int? sizeBytes,

    /// Context window length in tokens (when known).
    int? contextLength,

    /// Model family or provider (e.g. "llama", "gpt", "claude").
    String? family,

    /// Parameter count description (e.g. "14B", "70B").
    String? parameterSize,

    /// Quantization level (e.g. "Q4_K_M"). Ollama-specific.
    String? quantizationLevel,
  }) = _ModelInfo;

  /// Globally unique identifier: `endpointId:modelId`.
  /// Used internally to avoid name collisions across endpoints.
  String get qualifiedId => '$endpointId:$id';

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
