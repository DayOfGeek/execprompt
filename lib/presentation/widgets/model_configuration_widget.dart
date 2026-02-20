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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/settings_provider.dart';

class ModelConfigurationWidget extends ConsumerStatefulWidget {
  const ModelConfigurationWidget({super.key});

  @override
  ConsumerState<ModelConfigurationWidget> createState() =>
      _ModelConfigurationWidgetState();
}

class _ModelConfigurationWidgetState
    extends ConsumerState<ModelConfigurationWidget> {
  late TextEditingController _systemPromptController;
  late TextEditingController _maxTokensController;
  late TextEditingController _contextSizeController;
  final bool _autoSave = true;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController();
    _maxTokensController = TextEditingController();
    _contextSizeController = TextEditingController();
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    _contextSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temperature = ref.watch(temperatureProvider);
    final topK = ref.watch(topKProvider);
    final topP = ref.watch(topPProvider);
    final numPredict = ref.watch(numPredictProvider);
    final repeatPenalty = ref.watch(repeatPenaltyProvider);
    final numCtx = ref.watch(numCtxProvider);
    final systemPrompt = ref.watch(systemPromptProvider);

    // Initialize controllers
    if (_systemPromptController.text.isEmpty && systemPrompt != null) {
      _systemPromptController.text = systemPrompt;
    }
    if (_maxTokensController.text.isEmpty && numPredict != null) {
      _maxTokensController.text = numPredict.toString();
    }
    if (_contextSizeController.text.isEmpty && numCtx != null) {
      _contextSizeController.text = numCtx.toString();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Model Configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Model Parameters'),
                        content: const SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Temperature (0.0-2.0)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Controls randomness. Lower = more focused, Higher = more creative'),
                              SizedBox(height: 8),
                              Text('Top-K (1-100)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Limits vocabulary to K most likely tokens'),
                              SizedBox(height: 8),
                              Text('Top-P (0.0-1.0)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Nucleus sampling - considers tokens with cumulative probability P'),
                              SizedBox(height: 8),
                              Text('Repeat Penalty (1.0-2.0)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Penalizes repeated words'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Parameter Info',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // System Prompt
            TextField(
              controller: _systemPromptController,
              decoration: const InputDecoration(
                labelText: 'System Prompt (Optional)',
                hintText: 'You are a helpful assistant...',
                border: OutlineInputBorder(),
                helperText: 'Sets the behavior and context for the model',
              ),
              maxLines: 3,
              onChanged: _autoSave
                  ? (value) => saveSystemPrompt(ref, value.isEmpty ? null : value)
                  : null,
            ),
            const SizedBox(height: 16),

            // Temperature
            Text('Temperature: ${temperature.toStringAsFixed(2)}'),
            Slider(
              value: temperature,
              min: 0.0,
              max: 2.0,
              divisions: 40,
              label: temperature.toStringAsFixed(2),
              onChanged: (value) {
                saveTemperature(ref, value);
              },
            ),
            const SizedBox(height: 8),

            // Top-K
            Text('Top-K: $topK'),
            Slider(
              value: topK.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              label: topK.toString(),
              onChanged: (value) {
                saveTopK(ref, value.round());
              },
            ),
            const SizedBox(height: 8),

            // Top-P
            Text('Top-P: ${topP.toStringAsFixed(2)}'),
            Slider(
              value: topP,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: topP.toStringAsFixed(2),
              onChanged: (value) {
                saveTopP(ref, value);
              },
            ),
            const SizedBox(height: 8),

            // Repeat Penalty
            Text('Repeat Penalty: ${repeatPenalty.toStringAsFixed(2)}'),
            Slider(
              value: repeatPenalty,
              min: 1.0,
              max: 2.0,
              divisions: 20,
              label: repeatPenalty.toStringAsFixed(2),
              onChanged: (value) {
                saveRepeatPenalty(ref, value);
              },
            ),
            const SizedBox(height: 16),

            // Advanced options
            ExpansionTile(
              title: const Text('Advanced Options'),
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _maxTokensController,
                  decoration: const InputDecoration(
                    labelText: 'Max Tokens (Optional)',
                    hintText: 'Leave empty for model default',
                    border: OutlineInputBorder(),
                    helperText: 'Maximum number of tokens to generate',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (_autoSave) {
                      final intValue = int.tryParse(value);
                      saveNumPredict(ref, intValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contextSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Context Size (Optional)',
                    hintText: 'Leave empty for model default',
                    border: OutlineInputBorder(),
                    helperText: 'Size of context window (e.g., 4096, 8192)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (_autoSave) {
                      final intValue = int.tryParse(value);
                      saveNumCtx(ref, intValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Reset to defaults button
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await saveTemperature(ref, 0.7);
                  await saveTopK(ref, 40);
                  await saveTopP(ref, 0.9);
                  await saveRepeatPenalty(ref, 1.1);
                  await saveNumPredict(ref, null);
                  await saveNumCtx(ref, null);
                  await saveSystemPrompt(ref, null);
                  _systemPromptController.clear();
                  _maxTokensController.clear();
                  _contextSizeController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset to default values')),
                    );
                  }
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
