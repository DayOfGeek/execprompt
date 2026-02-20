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

part 'pull_request.freezed.dart';
part 'pull_request.g.dart';

@freezed
class PullRequest with _$PullRequest {
  const factory PullRequest({
    required String model,
    @Default(false) bool insecure,
    @Default(true) bool stream,
  }) = _PullRequest;

  factory PullRequest.fromJson(Map<String, dynamic> json) =>
      _$PullRequestFromJson(json);
}

@freezed
class PullProgress with _$PullProgress {
  const factory PullProgress({
    required String status,
    String? digest,
    int? total,
    int? completed,
  }) = _PullProgress;

  factory PullProgress.fromJson(Map<String, dynamic> json) =>
      _$PullProgressFromJson(json);
}
