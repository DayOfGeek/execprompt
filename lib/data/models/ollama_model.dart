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

part 'ollama_model.freezed.dart';
part 'ollama_model.g.dart';

@freezed
class OllamaModel with _$OllamaModel {
  const factory OllamaModel({
    required String name,
    String? model,
    String? modifiedAt,
    required int size,
    String? digest,
    ModelDetails? details,
  }) = _OllamaModel;

  factory OllamaModel.fromJson(Map<String, dynamic> json) =>
      _$OllamaModelFromJson(json);
}

@freezed
class ModelDetails with _$ModelDetails {
  const factory ModelDetails({
    String? parentModel,
    String? format,
    String? family,
    List<String>? families,
    String? parameterSize,
    String? quantizationLevel,
  }) = _ModelDetails;

  factory ModelDetails.fromJson(Map<String, dynamic> json) =>
      _$ModelDetailsFromJson(json);
}

@freezed
class ModelsResponse with _$ModelsResponse {
  const factory ModelsResponse({
    required List<OllamaModel> models,
  }) = _ModelsResponse;

  factory ModelsResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelsResponseFromJson(json);
}
