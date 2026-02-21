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
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Reusable tool settings panel that renders identically in:
///   - DetailPanel (tablet/desktop, inline section)
///   - endDrawer flyout (mobile, slide-in from right)
///
/// Contains toggles for tools (web search first, extensible for future tools)
/// and search provider configuration.
class ToolSettingsPanel extends ConsumerWidget {
  /// If true, renders as a full drawer with header + close.
  /// If false, renders as an inline section (for DetailPanel embedding).
  final bool isDrawer;

  const ToolSettingsPanel({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);
    final searchProvider = ref.watch(searchProviderProvider);
    final isSearchAvailable = ref.watch(isSearchAvailableProvider);
    final maxResults = ref.watch(searchMaxResultsProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: isDrawer ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isDrawer) ...[
          // Drawer header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '▸ TOOLS',
                    style: mono.copyWith(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textDim, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.border),
        ],

        // ── Web Search Toggle ──
        _ToolToggleRow(
          label: 'Web Search',
          description: webSearchEnabled
              ? (isSearchAvailable ? 'ON' : 'NO KEY')
              : 'OFF',
          icon: Icons.travel_explore,
          isEnabled: webSearchEnabled,
          statusColor: webSearchEnabled
              ? (isSearchAvailable ? colors.primary : colors.accent)
              : colors.textDim,
          onTap: () {
            HapticFeedback.selectionClick();
            final newValue = !webSearchEnabled;
            ref.read(webSearchEnabledProvider.notifier).state = newValue;
            if (newValue && !isSearchAvailable) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: colors.surface,
                  content: Text(
                    '> No search provider configured — set an API key in Settings',
                    style: mono.copyWith(fontSize: 11, color: colors.textColor),
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'SETTINGS',
                    textColor: colors.accent,
                    onPressed: () {
                      if (isDrawer) {
                        Navigator.of(context).pop(); // close drawer first
                      }
                      context.push('/settings');
                    },
                  ),
                ),
              );
            }
          },
          colors: colors,
          mono: mono,
        ),

        // ── Search Config (visible when web search is enabled) ──
        if (webSearchEnabled) ...[
          Container(
            height: 1,
            color: colors.border.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Provider selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Provider',
              style: mono.copyWith(color: colors.textDim, fontSize: 10),
            ),
          ),
          ...SearchProvider.values.map((provider) {
            final isSelected = searchProvider == provider;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                saveSearchProvider(ref, provider);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                child: Row(
                  children: [
                    Text(
                      isSelected ? '● ' : '○ ',
                      style: mono.copyWith(
                        color:
                            isSelected ? colors.primary : colors.textDim,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _providerLabel(provider),
                        style: mono.copyWith(
                          color: isSelected
                              ? colors.primary
                              : colors.textColor,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Max results
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Max Results',
                    style:
                        mono.copyWith(color: colors.textDim, fontSize: 10),
                  ),
                ),
                Text(
                  '$maxResults',
                  style: mono.copyWith(
                    color: colors.textColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: colors.primary,
                inactiveTrackColor: colors.border,
                thumbColor: colors.primary,
                overlayColor: colors.primary.withOpacity(0.1),
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: maxResults.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) =>
                    saveSearchMaxResults(ref, v.round()),
              ),
            ),
          ),

          // Status hint
          if (!isSearchAvailable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                searchProvider == SearchProvider.tavily
                    ? '⚠ Set Tavily key in Settings'
                    : searchProvider == SearchProvider.ollamaCloud
                        ? '⚠ Set Ollama Cloud search key in Settings'
                        : '⚠ Set a search key in Settings',
                style: mono.copyWith(
                  color: colors.accent,
                  fontSize: 10,
                ),
              ),
            ),
        ],

        if (!isDrawer) const SizedBox(height: 4),

        // ── Future tools placeholder ──
        // More tools will appear here as they are implemented.
        // The toggle pattern is extensible: just add another _ToolToggleRow.
      ],
    );

    if (isDrawer) {
      return Material(
        color: colors.surface,
        child: SafeArea(
          child: SizedBox(
            width: 260,
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  String _providerLabel(SearchProvider provider) {
    switch (provider) {
      case SearchProvider.auto:
        return 'Auto';
      case SearchProvider.ollamaCloud:
        return 'Ollama Cloud';
      case SearchProvider.tavily:
        return 'Tavily';
    }
  }
}

/// A single tool toggle row — on/off with an icon, label, and status.
class _ToolToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isEnabled;
  final Color statusColor;
  final VoidCallback onTap;
  final CyberTermColors colors;
  final TextStyle mono;

  const _ToolToggleRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.isEnabled,
    required this.statusColor,
    required this.onTap,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isEnabled ? colors.primary : colors.textDim,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: mono.copyWith(
                  color: isEnabled ? colors.primary : colors.textColor,
                  fontSize: 12,
                  fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                ),
                color: isEnabled
                    ? statusColor.withOpacity(0.1)
                    : null,
              ),
              child: Text(
                description,
                style: mono.copyWith(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
