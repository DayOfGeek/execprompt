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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/endpoint.dart';
import '../../data/services/api_adapter.dart';
import '../../data/services/anthropic_adapter.dart';
import '../../data/services/ollama_adapter.dart';
import '../../data/services/openai_adapter.dart';
import 'settings_provider.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kEndpointsKey = 'endpoints_json';
const _kApiKeyPrefix = 'endpoint_apikey_';
const _kMigrationDoneKey = 'legacy_endpoint_migrated';

// ---------------------------------------------------------------------------
// Secure storage provider
// ---------------------------------------------------------------------------

/// Provides access to encrypted key storage.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ---------------------------------------------------------------------------
// Endpoint state notifier
// ---------------------------------------------------------------------------

/// Manages the list of configured endpoints with CRUD operations,
/// persistence (SharedPreferences for metadata, flutter_secure_storage
/// for API keys), and legacy settings migration.
class EndpointsNotifier extends StateNotifier<List<Endpoint>> {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _uuid = Uuid();

  EndpointsNotifier(this._prefs, this._secure) : super([]);

  // ── Initialization ──────────────────────────────────────────────────────

  /// Load endpoints from storage and run migration if needed.
  /// Call this once from main() or from a FutureProvider.
  Future<void> init() async {
    // Yield to break out of any synchronous provider build phase.
    // Without this, setting state on a fresh install (no stored endpoints)
    // would trigger Riverpod's "providers must not modify other providers
    // during their initialization" assertion.
    await Future<void>.value();
    await _loadEndpoints();
    await _migrateLegacySettings();
  }

  Future<void> _loadEndpoints() async {
    final json = _prefs.getString(_kEndpointsKey);
    if (json == null || json.isEmpty) {
      state = [];
      return;
    }
    try {
      final list = jsonDecode(json) as List<dynamic>;
      final endpoints = <Endpoint>[];
      for (final item in list) {
        final endpoint = Endpoint.fromJson(item as Map<String, dynamic>);
        // Hydrate the transient API key from secure storage
        final key = await _secure.read(key: '$_kApiKeyPrefix${endpoint.id}');
        endpoints.add(endpoint.copyWith(apiKey: key));
      }
      state = endpoints;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to load endpoints: $e');
      state = [];
    }
  }

  /// Transparently migrate legacy `base_url` / `api_key` settings into a
  /// default Ollama endpoint. This runs once and is idempotent.
  Future<void> _migrateLegacySettings() async {
    if (_prefs.getBool(_kMigrationDoneKey) == true) return;

    final legacyUrl = _prefs.getString('base_url');
    if (legacyUrl == null || legacyUrl.trim().isEmpty) {
      // Nothing to migrate — mark done so we don't check again.
      await _prefs.setBool(_kMigrationDoneKey, true);
      return;
    }

    // Check if we already have an endpoint with this URL (e.g. user
    // manually created one before migration ran).
    final alreadyExists = state.any(
      (e) => e.baseUrl.trim().toLowerCase() == legacyUrl.trim().toLowerCase(),
    );
    if (alreadyExists) {
      await _prefs.setBool(_kMigrationDoneKey, true);
      return;
    }

    final legacyKey = _prefs.getString('api_key');
    final legacyModel = _prefs.getString('selected_model');

    final endpoint = Endpoint(
      id: _uuid.v4(),
      name: 'Ollama',
      baseUrl: legacyUrl.trim(),
      type: EndpointType.ollama,
      selectedModels: legacyModel != null ? [legacyModel] : [],
      sortOrder: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      apiKey: legacyKey,
    );

    await addEndpoint(endpoint);

    // Migrate the API key to secure storage.
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _secure.write(
        key: '$_kApiKeyPrefix${endpoint.id}',
        value: legacyKey,
      );
    }

    await _prefs.setBool(_kMigrationDoneKey, true);
    if (kDebugMode) debugPrint('✅ Migrated legacy Ollama settings → endpoint "${endpoint.name}"');
  }

  // ── CRUD ────────────────────────────────────────────────────────────────

  /// Add a new endpoint and persist.
  Future<void> addEndpoint(Endpoint endpoint) async {
    state = [...state, endpoint];
    await _persist();

    // Store API key securely if provided.
    if (endpoint.apiKey != null && endpoint.apiKey!.isNotEmpty) {
      await _secure.write(
        key: '$_kApiKeyPrefix${endpoint.id}',
        value: endpoint.apiKey,
      );
    }
  }

  /// Update an existing endpoint (matched by [endpoint.id]) and persist.
  Future<void> updateEndpoint(Endpoint endpoint) async {
    state = [
      for (final e in state)
        if (e.id == endpoint.id) endpoint else e,
    ];
    await _persist();

    // Update API key in secure storage.
    if (endpoint.apiKey != null && endpoint.apiKey!.isNotEmpty) {
      await _secure.write(
        key: '$_kApiKeyPrefix${endpoint.id}',
        value: endpoint.apiKey,
      );
    } else {
      await _secure.delete(key: '$_kApiKeyPrefix${endpoint.id}');
    }
  }

  /// Delete an endpoint by ID and clean up its API key.
  Future<void> deleteEndpoint(String endpointId) async {
    state = state.where((e) => e.id != endpointId).toList();
    await _persist();
    await _secure.delete(key: '$_kApiKeyPrefix$endpointId');
  }

  /// Reorder endpoints (e.g. after drag-and-drop in Settings).
  Future<void> reorderEndpoints(List<String> orderedIds) async {
    final map = {for (final e in state) e.id: e};
    state = [
      for (var i = 0; i < orderedIds.length; i++)
        if (map.containsKey(orderedIds[i]))
          map[orderedIds[i]]!.copyWith(sortOrder: i),
    ];
    await _persist();
  }

  /// Toggle the [isActive] flag on an endpoint.
  Future<void> toggleEndpoint(String endpointId, {required bool isActive}) async {
    state = [
      for (final e in state)
        if (e.id == endpointId) e.copyWith(isActive: isActive) else e,
    ];
    await _persist();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    await _prefs.setString(_kEndpointsKey, json);
  }

  // ── API Key helpers ─────────────────────────────────────────────────────

  /// Read an API key from secure storage for a given endpoint.
  Future<String?> getApiKey(String endpointId) async {
    return _secure.read(key: '$_kApiKeyPrefix$endpointId');
  }

  /// Write an API key to secure storage for a given endpoint.
  Future<void> setApiKey(String endpointId, String? key) async {
    if (key != null && key.isNotEmpty) {
      await _secure.write(key: '$_kApiKeyPrefix$endpointId', value: key);
    } else {
      await _secure.delete(key: '$_kApiKeyPrefix$endpointId');
    }

    // Also update the in-memory state so providers downstream see the change.
    state = [
      for (final e in state)
        if (e.id == endpointId) e.copyWith(apiKey: key) else e,
    ];
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// The main endpoints provider — source of truth for all configured endpoints.
final endpointsProvider =
    StateNotifierProvider<EndpointsNotifier, List<Endpoint>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secure = ref.watch(secureStorageProvider);
  return EndpointsNotifier(prefs, secure);
});

/// Initialization provider — awaited once at startup to load endpoints and
/// run migration. Use `ref.watch(endpointsInitProvider)` in a FutureBuilder
/// or similar.
final endpointsInitProvider = FutureProvider<void>((ref) async {
  final notifier = ref.read(endpointsProvider.notifier);
  await notifier.init();
});

/// Active endpoints only (filtered by [isActive]).
final activeEndpointsProvider = Provider<List<Endpoint>>((ref) {
  return ref.watch(endpointsProvider).where((e) => e.isActive).toList();
});

/// Look up which endpoint owns a given model name.
///
/// Returns the first active endpoint whose [selectedModels] contains
/// [modelName]. Returns `null` if no match (e.g. orphaned model selection).
final endpointForModelProvider =
    Provider.family<Endpoint?, String>((ref, modelName) {
  final endpoints = ref.watch(activeEndpointsProvider);

  // First try exact match on qualified ID (endpointId:modelId).
  // Endpoint IDs are UUIDs so they always contain hyphens. Ollama model
  // tags like "gpt-oss:120b" also contain colons but the part before the
  // colon is NOT a UUID, so we gate on the hyphen+hex pattern.
  if (modelName.contains(':')) {
    final endpointId = modelName.split(':').first;
    // UUID v4 always contains at least one hyphen — cheap guard to avoid
    // confusing Ollama tags (e.g. "llama3:70b") with qualified IDs.
    if (endpointId.contains('-') && endpointId.length >= 36) {
      final match = endpoints.firstWhereOrNull((e) => e.id == endpointId);
      if (match != null) return match;
    }
  }

  // Search selectedModels lists (handles both "model:tag" and plain names).
  return endpoints.firstWhereOrNull(
    (e) => e.selectedModels.contains(modelName),
  );
});

/// Resolve an [ApiAdapter] for a given endpoint.
///
/// The adapter is lazily created and cached per endpoint configuration.
/// When endpoint settings change (URL, key), a new adapter is returned.
final adapterForEndpointProvider =
    Provider.family<ApiAdapter, Endpoint>((ref, endpoint) {
  switch (endpoint.type) {
    case EndpointType.ollama:
      return OllamaAdapter(
        baseUrl: endpoint.baseUrl,
        endpointId: endpoint.id,
        endpointName: endpoint.name,
        apiKey: endpoint.apiKey,
      );
    case EndpointType.openai:
      return OpenAiAdapter(
        baseUrl: endpoint.baseUrl,
        endpointId: endpoint.id,
        endpointName: endpoint.name,
        apiKey: endpoint.apiKey,
      );
    case EndpointType.anthropic:
      return AnthropicAdapter(
        baseUrl: endpoint.baseUrl,
        endpointId: endpoint.id,
        endpointName: endpoint.name,
        apiKey: endpoint.apiKey,
      );
  }
});

// ---------------------------------------------------------------------------
// Extension: Iterable helpers (avoid importing collection just for this)
// ---------------------------------------------------------------------------

extension _IterableFirstWhereOrNull<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
