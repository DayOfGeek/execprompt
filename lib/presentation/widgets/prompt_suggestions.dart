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
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Retro terminal-style empty state with tappable prompt suggestions
class PromptSuggestions extends StatelessWidget {
  final String? selectedModel;
  final String? serverStatus;
  final bool isServerConfigured;
  final Function(String prompt) onPromptTap;

  const PromptSuggestions({
    super.key,
    this.selectedModel,
    this.serverStatus,
    this.isServerConfigured = true,
    required this.onPromptTap,
  });

  static const List<Map<String, String>> _suggestions = [
    {'label': 'Explain quantum computing', 'prompt': 'Explain quantum computing in simple terms'},
    {'label': 'Write a sorting algorithm', 'prompt': 'Write a Python quicksort implementation with comments'},
    {'label': 'Debug my code', 'prompt': 'Help me debug this code. I\'m getting an error:'},
    {'label': 'Creative writing', 'prompt': 'Write a short cyberpunk story set in a neon-lit city'},
    {'label': 'Summarize a topic', 'prompt': 'Give me a concise summary of how neural networks work'},
    {'label': 'Translate code', 'prompt': 'Translate this Python code to Dart:'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Boot sequence header
          Text(
            '> EXECPROMPT v1.0 [READY]',
            style: mono.copyWith(
              color: colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (!isServerConfigured) ...[  
            Text(
              '> NO ENDPOINTS CONFIGURED',
              style: mono.copyWith(color: colors.error, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '> Go to Settings to add an endpoint',
              style: mono.copyWith(color: colors.textDim, fontSize: 11),
            ),
            const SizedBox(height: 4),
          ] else if (selectedModel != null) ...[
            Text(
              '> MODEL: $selectedModel',
              style: mono.copyWith(color: colors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 4),
          ] else ...[
            Text(
              '> NO MODEL SELECTED — go to Models',
              style: mono.copyWith(color: colors.error, fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '> ${DateTime.now().toString().substring(0, 19)}',
            style: mono.copyWith(color: colors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 24),
          // Divider
          Container(
            height: 1,
            color: colors.border,
          ),
          const SizedBox(height: 24),
          Text(
            '> SUGGESTED PROMPTS:',
            style: mono.copyWith(
              color: colors.primaryDim,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Suggestion chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPromptTap(s['prompt']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    color: colors.surface,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '> ',
                        style: mono.copyWith(
                          color: colors.primaryDim,
                          fontSize: 12,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          s['label']!,
                          style: mono.copyWith(
                            color: colors.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            height: 1,
            color: colors.border,
          ),
          const SizedBox(height: 16),
          Text(
            '> TYPE A MESSAGE TO BEGIN_',
            style: mono.copyWith(
              color: colors.textDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
