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


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/web_search_service.dart';
import '../../data/services/ollama_cloud_search_service.dart';
import '../../data/services/tavily_search_service.dart';
import '../models/tool_definition.dart';
import 'settings_provider.dart';

/// Resolved search service — auto-selects based on user config.
/// Returns null if no provider is available.
final webSearchServiceProvider = Provider<WebSearchService?>((ref) {
  final provider = ref.watch(searchProviderProvider);
  final ollamaSearchKey = ref.watch(ollamaCloudSearchKeyProvider);
  final tavilyKey = ref.watch(tavilyApiKeyProvider);

  switch (provider) {
    case SearchProvider.auto:
      if (ollamaSearchKey != null && ollamaSearchKey.isNotEmpty) {
        return OllamaCloudSearchService(apiKey: ollamaSearchKey);
      }
      if (tavilyKey != null && tavilyKey.isNotEmpty) {
        return TavilySearchService(apiKey: tavilyKey);
      }
      return null;
    case SearchProvider.ollamaCloud:
      return (ollamaSearchKey != null && ollamaSearchKey.isNotEmpty)
          ? OllamaCloudSearchService(apiKey: ollamaSearchKey)
          : null;
    case SearchProvider.tavily:
      return (tavilyKey != null && tavilyKey.isNotEmpty)
          ? TavilySearchService(apiKey: tavilyKey)
          : null;
  }
});

/// Tool definitions registry.
/// Maps tool name → ToolDefinition for lookup during execution.
/// Only includes tools whose backing services are available.
final toolRegistryProvider = Provider<Map<String, ToolDefinition>>((ref) {
  final searchService = ref.watch(webSearchServiceProvider);
  final maxResults = ref.watch(searchMaxResultsProvider);

  return {
    if (searchService != null)
      'web_search': WebSearchToolDefinition(
        searchService: searchService,
        maxResults: maxResults,
      ),
  };
});

/// The Ollama-compatible tools JSON array to attach to chat requests.
/// Empty list when no tools are enabled.
final activeToolsJsonProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final webSearchEnabled = ref.watch(webSearchEnabledProvider);
  final registry = ref.watch(toolRegistryProvider);

  final tools = <Map<String, dynamic>>[];

  if (webSearchEnabled && registry.containsKey('web_search')) {
    tools.add(registry['web_search']!.toToolJson());
  }

  return tools;
});
