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
import '../../data/models/model_info.dart';
import '../../data/models/ollama_model.dart';
import 'endpoint_provider.dart';
import 'settings_provider.dart';


/// Legacy models list provider — fetches from the configured Ollama instance.
/// Kept for backward compatibility (used by the Models management screen
/// for pull/delete which are Ollama-only features).
final modelsProvider = FutureProvider<List<OllamaModel>>((ref) async {
  final isConfigured = ref.watch(isServerConfiguredProvider);
  if (!isConfigured) {
    throw StateError('SERVER_NOT_CONFIGURED');
  }
  final apiService = ref.watch(ollamaApiServiceProvider);
  return await apiService.listModels();
});

/// Model pull state
class ModelPullState {
  final String modelName;
  final bool isLoading;
  final double progress;
  final String status;
  final String? error;

  ModelPullState({
    required this.modelName,
    this.isLoading = false,
    this.progress = 0.0,
    this.status = '',
    this.error,
  });

  ModelPullState copyWith({
    String? modelName,
    bool? isLoading,
    double? progress,
    String? status,
    String? error,
  }) {
    return ModelPullState(
      modelName: modelName ?? this.modelName,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error,
    );
  }
}

/// Model pull state notifier
class ModelPullNotifier extends StateNotifier<Map<String, ModelPullState>> {
  final Ref ref;

  ModelPullNotifier(this.ref) : super({});

  Future<void> pullModel(String modelName) async {
    state = {
      ...state,
      modelName: ModelPullState(
        modelName: modelName,
        isLoading: true,
        status: 'Starting download...',
      ),
    };

    try {
      final apiService = ref.read(ollamaApiServiceProvider);
      await for (final progress in apiService.pullModel(modelName)) {
        final currentState = state[modelName]!;
        
        double progressValue = 0.0;
        if (progress.total != null && progress.total! > 0 && progress.completed != null) {
          progressValue = progress.completed! / progress.total!;
        }

        state = {
          ...state,
          modelName: currentState.copyWith(
            progress: progressValue,
            status: progress.status,
          ),
        };

        if (progress.status == 'success') {
          state = {
            ...state,
            modelName: currentState.copyWith(
              isLoading: false,
              progress: 1.0,
              status: 'Download complete',
            ),
          };
          // Refresh models list
          ref.invalidate(modelsProvider);
          break;
        }
      }
    } catch (e) {
      state = {
        ...state,
        modelName: ModelPullState(
          modelName: modelName,
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  void clearPullState(String modelName) {
    final newState = Map<String, ModelPullState>.from(state);
    newState.remove(modelName);
    state = newState;
  }
}

final modelPullProvider =
    StateNotifierProvider<ModelPullNotifier, Map<String, ModelPullState>>(
        (ref) => ModelPullNotifier(ref));

// ---------------------------------------------------------------------------
// Multi-endpoint model aggregation
// ---------------------------------------------------------------------------

/// All models across all active endpoints, grouped by endpoint name.
///
/// Returns a map: `{ "Ollama Cloud": [model1, model2], "OpenRouter": [model3, ...] }`
/// Only includes models that the user has curated (in [Endpoint.selectedModels]).
final allModelsProvider =
    FutureProvider<Map<String, List<ModelInfo>>>((ref) async {
  final endpoints = ref.watch(activeEndpointsProvider);
  final result = <String, List<ModelInfo>>{};

  for (final endpoint in endpoints) {
    try {
      final adapter = ref.read(adapterForEndpointProvider(endpoint));
      final allModels = await adapter.listModels();

      // Filter to only curated models (or all if selectedModels is empty
      // for legacy endpoints).
      final curated = endpoint.selectedModels.isEmpty
          ? allModels
          : allModels
              .where((m) => endpoint.selectedModels.contains(m.id))
              .toList();

      if (curated.isNotEmpty) {
        result[endpoint.name] = curated;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to load models for "${endpoint.name}": $e');
      // Still show the endpoint with its selected models even if fetch fails
      if (endpoint.selectedModels.isNotEmpty) {
        result[endpoint.name] = endpoint.selectedModels
            .map((id) => ModelInfo(
                  id: id,
                  displayName: id,
                  endpointId: endpoint.id,
                  endpointName: endpoint.name,
                ))
            .toList();
      }
    }
  }

  return result;
});

/// Flat list of all curated model IDs across all active endpoints.
/// Useful for the model picker search.
final allModelIdsProvider = Provider<List<ModelInfo>>((ref) {
  final modelsAsync = ref.watch(allModelsProvider);
  return modelsAsync.when(
    data: (grouped) => grouped.values.expand((list) => list).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
