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

part 'chat_options.freezed.dart';
part 'chat_options.g.dart';

@freezed
class ChatOptions with _$ChatOptions {
  const factory ChatOptions({
    @Default(0.7) double temperature,
    @Default(40) int topK,
    @Default(0.9) double topP,
    int? numPredict,
    @Default(1.1) double repeatPenalty,
    int? seed,
    int? numCtx,
  }) = _ChatOptions;

  factory ChatOptions.fromJson(Map<String, dynamic> json) =>
      _$ChatOptionsFromJson(json);
}

/// Extension to convert ChatOptions to Ollama API format
extension ChatOptionsExtension on ChatOptions {
  Map<String, dynamic> toMap() => {
    'temperature': temperature,
    'top_k': topK,
    'top_p': topP,
    if (numPredict != null) 'num_predict': numPredict,
    'repeat_penalty': repeatPenalty,
    if (seed != null) 'seed': seed,
    if (numCtx != null) 'num_ctx': numCtx,
  };
}
