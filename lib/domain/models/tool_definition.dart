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


import 'dart:convert';
import '../../data/services/web_search_service.dart';

/// Abstract base for all tool definitions.
/// Each tool knows how to describe itself (for the Ollama API)
/// and how to execute itself when called by the model.
abstract class ToolDefinition {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;

  /// Convert to the standard `tools` array entry format.
  /// Compatible with Ollama, OpenAI, and (after conversion) Anthropic.
  Map<String, dynamic> toToolJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parametersSchema,
        },
      };

  /// Alias for backward compatibility.
  Map<String, dynamic> toOllamaToolJson() => toToolJson();

  /// Execute the tool with the given arguments.
  /// Returns a string result to inject as a tool message.
  Future<String> execute(Map<String, dynamic> arguments);
}

/// Web search tool definition.
class WebSearchToolDefinition extends ToolDefinition {
  final WebSearchService searchService;
  final int maxResults;

  WebSearchToolDefinition({
    required this.searchService,
    this.maxResults = 5,
  });

  @override
  String get name => 'web_search';

  @override
  String get description => 'Search the web for current information';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': 'The search query',
          },
          'max_results': {
            'type': 'integer',
            'description': 'Maximum number of results to return',
          },
        },
        'required': ['query'],
      };

  @override
  Future<String> execute(Map<String, dynamic> arguments) async {
    final query = arguments['query'] as String? ?? '';
    final numResults = (arguments['max_results'] as int?) ?? maxResults;

    if (query.isEmpty) {
      return jsonEncode({'error': 'Empty search query'});
    }

    try {
      final results = await searchService.search(
        query: query,
        maxResults: numResults,
      );

      if (results.isEmpty) {
        return jsonEncode({'message': 'No results found for: $query'});
      }

      return jsonEncode(results.map((r) => r.toJson()).toList());
    } catch (e) {
      return jsonEncode({'error': 'Search failed: $e'});
    }
  }
}
