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
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/endpoint.dart';
import '../../data/models/model_info.dart';
import '../../domain/providers/endpoint_provider.dart';
import '../../domain/providers/models_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allModelsAsync = ref.watch(allModelsProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final endpoints = ref.watch(activeEndpointsProvider);
    final isConfigured = ref.watch(isServerConfiguredProvider);
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    // Whether any endpoint is Ollama type (for pull FAB)
    final hasOllamaEndpoint =
        endpoints.any((e) => e.type == EndpointType.ollama);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '▸ MODELS',
          style: mono.copyWith(
            color: colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          InkWell(
            onTap: () => ref.invalidate(allModelsProvider),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '[REFRESH]',
                style: mono.copyWith(
                  color: colors.primaryDim,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: !isConfigured
          ? _buildNotConfigured(context, mono, colors)
          : allModelsAsync.when(
              data: (grouped) {
                if (grouped.isEmpty) {
                  return _buildNoModels(context, mono, colors);
                }
                return _buildModelList(
                    context, ref, grouped, selectedModel, mono, colors);
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text('> Loading models...',
                        style: mono.copyWith(
                            color: colors.textDim, fontSize: 12)),
                  ],
                ),
              ),
              error: (error, stack) =>
                  _buildError(context, ref, error, mono, colors),
            ),
      floatingActionButton: hasOllamaEndpoint
          ? FloatingActionButton(
              onPressed: () => _showPullModelDialog(context, ref),
              tooltip: 'Pull model',
              child: Text(
                '↓',
                style:
                    mono.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  // ── Empty / error states ────────────────────────────────────────────────

  Widget _buildNotConfigured(
      BuildContext context, TextStyle mono, CyberTermColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('▸ NO ENDPOINTS CONFIGURED',
                style: mono.copyWith(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Welcome to ExecPrompt!\n\n'
              'Add an endpoint in Settings to\n'
              'connect to your AI provider.',
              textAlign: TextAlign.center,
              style: mono.copyWith(color: colors.textDim, fontSize: 11),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => context.push('/settings'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration:
                    BoxDecoration(border: Border.all(color: colors.primary)),
                child: Text('[SETTINGS]',
                    style: mono.copyWith(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoModels(
      BuildContext context, TextStyle mono, CyberTermColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '> NO MODELS AVAILABLE',
            style: mono.copyWith(color: colors.textDim, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Select models in your endpoint\n'
            'configuration, or pull a model\n'
            'from an Ollama endpoint.',
            textAlign: TextAlign.center,
            style: mono.copyWith(color: colors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => context.push('/settings'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: colors.primary),
                color: colors.primary.withOpacity(0.1),
              ),
              child: Text(
                '[SETTINGS]',
                style: mono.copyWith(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error,
      TextStyle mono, CyberTermColors colors) {
    final errorStr = error.toString().toLowerCase();
    final isConnectionError = errorStr.contains('connection refused') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('handshake');
    final isTimeoutError =
        errorStr.contains('timeout') || errorStr.contains('timed out');

    final String title;
    final String message;
    if (isConnectionError) {
      title = '✕ CONNECTION FAILED';
      message = 'Cannot reach one or more endpoints.\n'
          'Check that servers are running and\n'
          'addresses are correct in Settings.';
    } else if (isTimeoutError) {
      title = '✕ TIMED OUT';
      message = 'An endpoint took too long to respond.\n'
          'Check your network connection.';
    } else {
      title = '✕ ERROR';
      message = error.toString();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: mono.copyWith(
                    color: colors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: mono.copyWith(color: colors.error, fontSize: 11),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: colors.textDim)),
                    child: Text('[SETTINGS]',
                        style: mono.copyWith(
                            color: colors.textDim,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => ref.invalidate(allModelsProvider),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: colors.primary)),
                    child: Text('[RETRY]',
                        style: mono.copyWith(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Model list ──────────────────────────────────────────────────────────

  Widget _buildModelList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<ModelInfo>> grouped,
    String? selectedModel,
    TextStyle mono,
    CyberTermColors colors,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allModelsProvider);
        await ref.read(allModelsProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          for (final entry in grouped.entries) ...[
            // Endpoint header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                '── ${entry.key.toUpperCase()} ──',
                style: mono.copyWith(
                  color: colors.primaryDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Models in this endpoint
            for (final model in entry.value)
              _buildModelTile(
                  context, ref, model, selectedModel, mono, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildModelTile(
    BuildContext context,
    WidgetRef ref,
    ModelInfo model,
    String? selectedModel,
    TextStyle mono,
    CyberTermColors colors,
  ) {
    final qualifiedId = model.qualifiedId;
    final isSelected =
        selectedModel == qualifiedId || selectedModel == model.id;

    // Build subtitle parts
    final subtitleParts = <String>[];
    if (model.parameterSize != null) subtitleParts.add(model.parameterSize!);
    if (model.sizeBytes != null) {
      final size = model.sizeBytes!;
      if (size >= 1024 * 1024 * 1024) {
        subtitleParts.add(
            '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)}G');
      } else {
        subtitleParts.add('${(size / 1024 / 1024).toStringAsFixed(0)}M');
      }
    }
    if (model.quantizationLevel != null) {
      subtitleParts.add(model.quantizationLevel!);
    }
    if (model.family != null) subtitleParts.add(model.family!);

    // Check if this model's endpoint is Ollama (for long-press options)
    final endpoints = ref.watch(activeEndpointsProvider);
    final isOllamaModel =
        endpoints.any((e) => e.id == model.endpointId && e.type == EndpointType.ollama);

    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        await saveSelectedModel(ref, qualifiedId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('> Selected: ${model.displayName}')),
          );
        }
      },
      onLongPress: isOllamaModel
          ? () {
              HapticFeedback.mediumImpact();
              _showModelOptions(context, ref, model.id);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withOpacity(0.1)
              : colors.surface,
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              isSelected ? '● ' : '○ ',
              style: mono.copyWith(
                color: isSelected ? colors.primary : colors.textDim,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.displayName,
                    style: mono.copyWith(
                      color:
                          isSelected ? colors.primary : colors.textColor,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' │ '),
                      style: mono.copyWith(
                          color: colors.textDim, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Text(
                '[ACT]',
                style: mono.copyWith(
                  color: colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPullModelDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('▸ PULL MODEL', style: mono.copyWith(color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: mono.copyWith(color: colors.textColor, fontSize: 12),
          decoration: InputDecoration(
            hintText: 'e.g., llama3.2, deepseek-r1:7b',
            hintStyle: mono.copyWith(color: colors.textDim, fontSize: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final modelName = controller.text.trim();
              if (modelName.isNotEmpty) {
                Navigator.of(context).pop();
                ref.read(modelPullProvider.notifier).pullModel(modelName);
                _showPullProgressDialog(context, ref, modelName);
              }
            },
            child: const Text('Pull'),
          ),
        ],
      ),
    );
  }

  void _showPullProgressDialog(BuildContext context, WidgetRef ref, String modelName) {
    final mono = GoogleFonts.jetBrainsMono();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final pullStates = ref.watch(modelPullProvider);
          final pullState = pullStates[modelName];
          final colors = Theme.of(context).cyberTermColors;

          if (pullState == null || !pullState.isLoading) {
            Future.microtask(() {
              if (context.mounted) {
                Navigator.of(context).pop();
                if (pullState?.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('> Error: ${pullState!.error}')),
                  );
                } else {
                  ref.invalidate(modelsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('> Pulled: $modelName')),
                  );
                }
              }
            });
            return const SizedBox.shrink();
          }

          return AlertDialog(
            title: Text('> Pulling $modelName', style: mono.copyWith(color: colors.primary, fontSize: 13)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: pullState.progress > 0 ? pullState.progress : null,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
                const SizedBox(height: 12),
                Text(pullState.status, style: mono.copyWith(color: colors.textDim, fontSize: 11)),
                if (pullState.progress > 0)
                  Text(
                    '${(pullState.progress * 100).toStringAsFixed(1)}%',
                    style: mono.copyWith(color: colors.primary, fontSize: 11),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showModelOptions(BuildContext context, WidgetRef ref, String modelName) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '▸ ${modelName.toUpperCase()}',
                style: mono.copyWith(color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Container(height: 1, color: colors.border),
            ListTile(
              leading: Icon(Icons.info_outline, color: colors.primaryDim, size: 18),
              title: Text('Details', style: mono.copyWith(color: colors.textColor, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showModelDetails(context, ref, modelName);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error, size: 18),
              title: Text('Delete', style: mono.copyWith(color: colors.error, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Model'),
                    content: Text('Delete $modelName? This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: colors.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  try {
                    final apiService = ref.read(ollamaApiServiceProvider);
                    await apiService.deleteModel(modelName);
                    ref.invalidate(modelsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('> Deleted: $modelName')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('> Error: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showModelDetails(BuildContext context, WidgetRef ref, String modelName) {
    final mono = GoogleFonts.jetBrainsMono();
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).cyberTermColors;
        return FutureBuilder<Map<String, dynamic>>(
          future: ref.read(ollamaApiServiceProvider).showModel(modelName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('> $modelName', style: mono.copyWith(color: colors.primary, fontSize: 13)),
                content: SizedBox(
                  height: 60,
                  child: Center(
                    child: Text('Loading...', style: mono.copyWith(color: colors.textDim, fontSize: 12)),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('> $modelName', style: mono.copyWith(color: colors.primary, fontSize: 13)),
                content: Text('Error: ${snapshot.error}', style: mono.copyWith(color: colors.error, fontSize: 11)),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              );
            }
            final data = snapshot.data!;
            final parameters = data['parameters'] as String? ?? 'N/A';
            final template = data['template'] as String? ?? 'N/A';
            final details = data['details'] as Map<String, dynamic>? ?? {};

            return AlertDialog(
              title: Text('> $modelName', style: mono.copyWith(color: colors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (details.isNotEmpty) ...[
                      _detailRow('Format', details['format']?.toString() ?? 'N/A', mono, colors),
                      _detailRow('Family', details['family']?.toString() ?? 'N/A', mono, colors),
                      _detailRow('Size', details['parameter_size']?.toString() ?? 'N/A', mono, colors),
                      _detailRow('Quant', details['quantization_level']?.toString() ?? 'N/A', mono, colors),
                      Container(height: 1, color: colors.border, margin: const EdgeInsets.symmetric(vertical: 6)),
                    ],
                    if (parameters != 'N/A')
                      _detailRow('Params', parameters, mono, colors),
                    if (template != 'N/A') ...[
                      Container(height: 1, color: colors.border, margin: const EdgeInsets.symmetric(vertical: 6)),
                      Text('Template:', style: mono.copyWith(color: colors.primaryDim, fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: colors.background,
                        child: SelectableText(
                          template,
                          style: mono.copyWith(color: colors.textDim, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, TextStyle mono, CyberTermColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: mono.copyWith(color: colors.primaryDim, fontSize: 10)),
          ),
          Expanded(
            child: Text(value, style: mono.copyWith(color: colors.textColor, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
