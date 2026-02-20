// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    String? content,
    String? thinking,
    List<String>? images,
    @JsonKey(name: 'tool_calls') List<ToolCallWrapper>? toolCalls,
    /// Ollama native: identifies the tool by name in the result message.
    @JsonKey(name: 'tool_name') String? toolName,
    /// OpenAI / Anthropic: identifies the tool call that this result answers.
    /// Required when sending tool results back to OpenAI-spec providers.
    @JsonKey(name: 'tool_call_id') String? toolCallId,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

/// Wrapper matching the tool call structure.
///
/// Ollama native format: `{function: {name, arguments}}`
/// OpenAI format:        `{id: "call_123", function: {name, arguments}}`
///
/// The [id] is null for Ollama native and populated for OpenAI/Anthropic.
@freezed
class ToolCallWrapper with _$ToolCallWrapper {
  const factory ToolCallWrapper({
    /// Tool call ID (OpenAI: "call_xxx", Anthropic: "toolu_xxx"). Null for Ollama.
    String? id,
    @JsonKey(name: 'function') required ToolCallFunction function_,
    /// Gemini thought signature — must be echoed back for tool result round-trips.
    @JsonKey(name: 'thought_signature') String? thoughtSignature,
  }) = _ToolCallWrapper;

  factory ToolCallWrapper.fromJson(Map<String, dynamic> json) =>
      _$ToolCallWrapperFromJson(json);
}

@freezed
class ToolCallFunction with _$ToolCallFunction {
  const factory ToolCallFunction({
    required String name,
    required Map<String, dynamic> arguments,
  }) = _ToolCallFunction;

  factory ToolCallFunction.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFunctionFromJson(json);
}
