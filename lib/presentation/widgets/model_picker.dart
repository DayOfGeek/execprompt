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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/model_info.dart';
import '../../domain/providers/endpoint_provider.dart';
import '../../domain/providers/models_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Shows a multi-endpoint model picker as a modal bottom sheet.
///
/// Models are grouped by endpoint name with searchable filtering.
/// Falls back to legacy Ollama-only provider when no endpoints are configured.
void showMultiModelPicker(BuildContext context, WidgetRef ref) {
  final colors = Theme.of(context).cyberTermColors;
  final mono = GoogleFonts.jetBrainsMono();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (ctx) {
      return _MultiModelPicker(colors: colors, mono: mono);
    },
  );
}

class _MultiModelPicker extends ConsumerStatefulWidget {
  final CyberTermColors colors;
  final TextStyle mono;

  const _MultiModelPicker({required this.colors, required this.mono});

  @override
  ConsumerState<_MultiModelPicker> createState() => _MultiModelPickerState();
}

class _MultiModelPickerState extends ConsumerState<_MultiModelPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final mono = widget.mono;
    final endpoints = ref.watch(activeEndpointsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final allModelsAsync = ref.watch(allModelsProvider);

    // If no endpoints configured, fall back to legacy Ollama models
    if (endpoints.isEmpty) {
      return _buildLegacyPicker(context, colors, mono);
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '▸ SELECT MODEL',
              style: mono.copyWith(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(height: 1, color: colors.border),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              style: mono.copyWith(color: colors.textColor, fontSize: 12),
              decoration: InputDecoration(
                hintText: '/ search models...',
                hintStyle: mono.copyWith(color: colors.textDim, fontSize: 12),
                prefixIcon:
                    Icon(Icons.search, size: 16, color: colors.textDim),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Container(height: 0.5, color: colors.border),

          // Model list
          Flexible(
            child: allModelsAsync.when(
              data: (grouped) {
                final widgets = <Widget>[];
                for (final entry in grouped.entries) {
                  final endpointName = entry.key;
                  final models = _filterModels(entry.value, _search);
                  if (models.isEmpty) continue;

                  // Endpoint group header
                  widgets.add(
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(
                          bottom:
                              BorderSide(color: colors.border, width: 0.5),
                        ),
                      ),
                      child: Text(
                        '── ${endpointName.toUpperCase()} ──',
                        style: mono.copyWith(
                          color: colors.primaryDim,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  );

                  // Model tiles
                  for (final model in models) {
                    final isSelected = selectedModel == model.id ||
                        selectedModel == model.qualifiedId;
                    widgets.add(
                      _ModelTile(
                        model: model,
                        isSelected: isSelected,
                        colors: colors,
                        mono: mono,
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          await saveSelectedModel(ref, model.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    );
                  }
                }

                if (widgets.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        _search.isNotEmpty
                            ? '> No models match "$_search"'
                            : '> No models available',
                        style: mono.copyWith(
                            color: colors.textDim, fontSize: 12),
                      ),
                    ),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: widgets,
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: colors.primaryDim),
                      ),
                      const SizedBox(width: 8),
                      Text('> Loading models...',
                          style: mono.copyWith(
                              color: colors.textDim, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('> Error: $e',
                    style:
                        mono.copyWith(color: colors.error, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Legacy picker for when no multi-endpoint configuration exists.
  Widget _buildLegacyPicker(
      BuildContext context, CyberTermColors colors, TextStyle mono) {
    final modelsAsync = ref.watch(modelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '▸ SELECT MODEL',
              style: mono.copyWith(
                color: colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(height: 1, color: colors.border),
          Flexible(
            child: modelsAsync.when(
              data: (models) => ListView.builder(
                shrinkWrap: true,
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final isSelected = selectedModel == model.name;
                  return InkWell(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await saveSelectedModel(ref, model.name);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: isSelected
                          ? colors.primary.withOpacity(0.1)
                          : null,
                      child: Row(
                        children: [
                          Text(
                            isSelected ? '● ' : '○ ',
                            style: mono.copyWith(
                              color: isSelected
                                  ? colors.primary
                                  : colors.textDim,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              model.name,
                              style: mono.copyWith(
                                color: isSelected
                                    ? colors.primary
                                    : colors.textColor,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            _formatSize(model.size),
                            style: mono.copyWith(
                                color: colors.textDim, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text('> Loading...',
                      style: mono.copyWith(
                          color: colors.textDim, fontSize: 12)),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('> Error: $e',
                    style:
                        mono.copyWith(color: colors.error, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ModelInfo> _filterModels(List<ModelInfo> models, String query) {
    if (query.isEmpty) return models;
    final q = query.toLowerCase();
    return models
        .where((m) =>
            m.id.toLowerCase().contains(q) ||
            m.displayName.toLowerCase().contains(q) ||
            (m.family?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)}G';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(0)}M';
  }
}

class _ModelTile extends StatelessWidget {
  final ModelInfo model;
  final bool isSelected;
  final CyberTermColors colors;
  final TextStyle mono;
  final VoidCallback onTap;

  const _ModelTile({
    required this.model,
    required this.isSelected,
    required this.colors,
    required this.mono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: isSelected ? colors.primary.withOpacity(0.1) : null,
        child: Row(
          children: [
            Text(
              isSelected ? '● ' : '○ ',
              style: mono.copyWith(
                color: isSelected ? colors.primary : colors.textDim,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: Text(
                model.displayName,
                style: mono.copyWith(
                  color: isSelected ? colors.primary : colors.textColor,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // sizeBytes omitted in multi-provider picker — only Ollama
            // reports it, making the column inconsistent across endpoints.
          ],
        ),
      ),
    );
  }
}
