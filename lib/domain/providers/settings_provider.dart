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


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/ollama_api_service.dart';
import '../../data/models/chat_options.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import 'endpoint_provider.dart';

/// Shared preferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Extract the raw model ID from a possibly-qualified ID.
/// Qualified format: `{endpointId}:{modelId}` → returns `modelId`.
/// Plain format: `llama3.2` → returns as-is.
String rawModelId(String qualifiedOrPlain) {
  if (qualifiedOrPlain.contains(':')) {
    // endpointId is a UUID (8-4-4-4-12), so the first ':' separates it.
    // However model IDs can also contain ':' (e.g. 'deepseek-r1:14b').
    // UUIDs are 36 chars, so split only if the prefix looks like a UUID.
    final firstColon = qualifiedOrPlain.indexOf(':');
    final prefix = qualifiedOrPlain.substring(0, firstColon);
    // UUID v4 pattern: 8-4-4-4-12 hex digits (case-insensitive)
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(prefix)) {
      return qualifiedOrPlain.substring(firstColon + 1);
    }
  }
  return qualifiedOrPlain;
}

/// Display-friendly model name (strips endpoint UUID prefix if present).
final selectedModelDisplayProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedModelProvider);
  if (selected == null) return null;
  return rawModelId(selected);
});

/// Settings providers
final baseUrlProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('base_url') ?? '';
});

/// Whether the server has been configured.
/// True when there is at least one active endpoint OR a legacy baseUrl.
final isServerConfiguredProvider = Provider<bool>((ref) {
  // New multi-endpoint system
  final endpoints = ref.watch(activeEndpointsProvider);
  if (endpoints.isNotEmpty) return true;
  // Legacy fallback: single Ollama base_url
  return ref.watch(baseUrlProvider).trim().isNotEmpty;
});

final apiKeyProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('api_key');
});

/// Ollama API service provider
final ollamaApiServiceProvider = Provider<OllamaApiService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final apiKey = ref.watch(apiKeyProvider);
  return OllamaApiService(
    baseUrl: baseUrl,
    apiKey: apiKey,
  );
});

/// Selected model provider
final selectedModelProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('selected_model');
});

/// When false, no optional parameters (temperature, top_p, etc.) are sent
/// in chat requests — the model uses its own defaults. This avoids 400
/// errors from providers that reject unsupported parameters (e.g. Gemini
/// rejects frequency_penalty, gpt-5-mini rejects temperature != 1).
final sendParametersProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('send_parameters') ?? true;
});

Future<void> saveSendParameters(WidgetRef ref, bool value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setBool('send_parameters', value);
  ref.read(sendParametersProvider.notifier).state = value;
}

/// Chat options providers
final temperatureProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('temperature') ?? 0.7;
});

final topKProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('top_k') ?? 40;
});

final topPProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('top_p') ?? 0.9;
});

final numPredictProvider = StateProvider<int?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final value = prefs.getInt('num_predict');
  return value == 0 ? null : value;
});

final repeatPenaltyProvider = StateProvider<double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getDouble('repeat_penalty') ?? 1.1;
});

final numCtxProvider = StateProvider<int?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final value = prefs.getInt('num_ctx');
  return value == 0 ? null : value;
});

/// System prompt provider
final systemPromptProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('system_prompt');
});

/// ── Tool / Web Search providers ──

/// Whether web search is enabled for the current session (not persisted to DB)
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

/// Search provider selection
enum SearchProvider { auto, ollamaCloud, tavily }

final searchProviderProvider = StateProvider<SearchProvider>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final value = prefs.getString('search_provider') ?? 'auto';
  return SearchProvider.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SearchProvider.auto,
  );
});

/// Search API keys — loaded asynchronously from secure storage via
/// [searchKeysInitProvider].  Start null; populated after init.
final ollamaCloudSearchKeyProvider = StateProvider<String?>((ref) => null);
final tavilyApiKeyProvider = StateProvider<String?>((ref) => null);

// Secure-storage key constants for search API keys.
const _kOllamaSearchKeySecure = 'search_key_ollama_cloud';
const _kTavilyKeySecure = 'search_key_tavily';

/// One-time async initializer: loads search keys from [FlutterSecureStorage]
/// and migrates any legacy plaintext keys from [SharedPreferences].
final searchKeysInitProvider = FutureProvider<void>((ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final secure = ref.read(secureStorageProvider);

  // --- Ollama Cloud Search key ---
  String? ollamaKey = await secure.read(key: _kOllamaSearchKeySecure);
  if (ollamaKey == null) {
    // Migrate from SharedPreferences if present.
    final legacy = prefs.getString('ollama_cloud_search_key');
    if (legacy != null && legacy.isNotEmpty) {
      await secure.write(key: _kOllamaSearchKeySecure, value: legacy);
      await prefs.remove('ollama_cloud_search_key');
      ollamaKey = legacy;
      if (kDebugMode) debugPrint('Migrated ollama_cloud_search_key → secure');
    }
  }
  ref.read(ollamaCloudSearchKeyProvider.notifier).state = ollamaKey;

  // --- Tavily key ---
  String? tavilyKey = await secure.read(key: _kTavilyKeySecure);
  if (tavilyKey == null) {
    final legacy = prefs.getString('tavily_api_key');
    if (legacy != null && legacy.isNotEmpty) {
      await secure.write(key: _kTavilyKeySecure, value: legacy);
      await prefs.remove('tavily_api_key');
      tavilyKey = legacy;
      if (kDebugMode) debugPrint('Migrated tavily_api_key → secure');
    }
  }
  ref.read(tavilyApiKeyProvider.notifier).state = tavilyKey;
});

final searchMaxResultsProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('search_max_results') ?? 5;
});

/// Whether a search provider is available (has required API key)
final isSearchAvailableProvider = Provider<bool>((ref) {
  final provider = ref.watch(searchProviderProvider);
  final ollamaSearchKey = ref.watch(ollamaCloudSearchKeyProvider);
  final tavilyKey = ref.watch(tavilyApiKeyProvider);

  switch (provider) {
    case SearchProvider.auto:
      return (ollamaSearchKey != null && ollamaSearchKey.isNotEmpty) ||
          (tavilyKey != null && tavilyKey.isNotEmpty);
    case SearchProvider.ollamaCloud:
      return ollamaSearchKey != null && ollamaSearchKey.isNotEmpty;
    case SearchProvider.tavily:
      return tavilyKey != null && tavilyKey.isNotEmpty;
  }
});

/// Theme provider
final themeProvider = StateProvider<CyberTermTheme>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final themeName = prefs.getString('theme') ?? 'p1Green';
  return CyberTermTheme.fromName(themeName);
});

Future<void> saveTheme(WidgetRef ref, CyberTermTheme theme) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('theme', theme.name);
  ref.read(themeProvider.notifier).state = theme;
}

/// Combined chat options provider
final chatOptionsProvider = Provider<ChatOptions>((ref) {
  return ChatOptions(
    temperature: ref.watch(temperatureProvider),
    topK: ref.watch(topKProvider),
    topP: ref.watch(topPProvider),
    numPredict: ref.watch(numPredictProvider),
    repeatPenalty: ref.watch(repeatPenaltyProvider),
    numCtx: ref.watch(numCtxProvider),
  );
});

/// Save settings
Future<void> saveBaseUrl(WidgetRef ref, String url) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('base_url', url);
  ref.read(baseUrlProvider.notifier).state = url;
}

Future<void> saveApiKey(WidgetRef ref, String? key) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (key != null && key.isNotEmpty) {
    await prefs.setString('api_key', key);
  } else {
    await prefs.remove('api_key');
  }
  ref.read(apiKeyProvider.notifier).state = key;
}

Future<void> saveSelectedModel(WidgetRef ref, String? model) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (model != null) {
    await prefs.setString('selected_model', model);
  } else {
    await prefs.remove('selected_model');
  }
  ref.read(selectedModelProvider.notifier).state = model;
}

Future<void> saveTemperature(WidgetRef ref, double value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setDouble('temperature', value);
  ref.read(temperatureProvider.notifier).state = value;
}

Future<void> saveTopK(WidgetRef ref, int value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setInt('top_k', value);
  ref.read(topKProvider.notifier).state = value;
}

Future<void> saveTopP(WidgetRef ref, double value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setDouble('top_p', value);
  ref.read(topPProvider.notifier).state = value;
}

Future<void> saveNumPredict(WidgetRef ref, int? value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (value != null) {
    await prefs.setInt('num_predict', value);
  } else {
    await prefs.remove('num_predict');
  }
  ref.read(numPredictProvider.notifier).state = value;
}

Future<void> saveRepeatPenalty(WidgetRef ref, double value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setDouble('repeat_penalty', value);
  ref.read(repeatPenaltyProvider.notifier).state = value;
}

Future<void> saveNumCtx(WidgetRef ref, int? value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (value != null) {
    await prefs.setInt('num_ctx', value);
  } else {
    await prefs.remove('num_ctx');
  }
  ref.read(numCtxProvider.notifier).state = value;
}

Future<void> saveSystemPrompt(WidgetRef ref, String? value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (value != null && value.isNotEmpty) {
    await prefs.setString('system_prompt', value);
  } else {
    await prefs.remove('system_prompt');
  }
  ref.read(systemPromptProvider.notifier).state = value;
}

Future<void> saveSearchProvider(WidgetRef ref, SearchProvider value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('search_provider', value.name);
  ref.read(searchProviderProvider.notifier).state = value;
}

Future<void> saveOllamaCloudSearchKey(WidgetRef ref, String? key) async {
  final secure = ref.read(secureStorageProvider);
  if (key != null && key.isNotEmpty) {
    await secure.write(key: _kOllamaSearchKeySecure, value: key);
  } else {
    await secure.delete(key: _kOllamaSearchKeySecure);
  }
  ref.read(ollamaCloudSearchKeyProvider.notifier).state = key;
}

Future<void> saveTavilyApiKey(WidgetRef ref, String? key) async {
  final secure = ref.read(secureStorageProvider);
  if (key != null && key.isNotEmpty) {
    await secure.write(key: _kTavilyKeySecure, value: key);
  } else {
    await secure.delete(key: _kTavilyKeySecure);
  }
  ref.read(tavilyApiKeyProvider.notifier).state = key;
}

Future<void> saveSearchMaxResults(WidgetRef ref, int value) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setInt('search_max_results', value);
  ref.read(searchMaxResultsProvider.notifier).state = value;
}
