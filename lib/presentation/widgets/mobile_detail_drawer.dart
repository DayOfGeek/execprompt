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
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import 'tool_settings_panel.dart';

/// Mobile/tablet end-drawer with feature parity to the desktop DetailPanel.
/// Contains: CONV STATS, PARAMETERS, TOOLS.
/// Omits THINKING — the drawer obscures the chat, so a live thinking stream
/// would burn cycles for no visible benefit. Thinking feedback is provided
/// via [ThinkingStatusIndicator] in the chat area instead.
class MobileDetailDrawer extends ConsumerStatefulWidget {
  const MobileDetailDrawer({super.key});

  @override
  ConsumerState<MobileDetailDrawer> createState() =>
      _MobileDetailDrawerState();
}

class _MobileDetailDrawerState extends ConsumerState<MobileDetailDrawer> {
  bool _statsExpanded = true;
  bool _paramsExpanded = false; // collapsed by default — mobile space is tight
  bool _toolsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    final chatState = ref.watch(chatProvider);
    final temperature = ref.watch(temperatureProvider);
    final topK = ref.watch(topKProvider);
    final topP = ref.watch(topPProvider);
    final repeatPenalty = ref.watch(repeatPenaltyProvider);
    final sendParams = ref.watch(sendParametersProvider);

    return Material(
      color: colors.surface,
      child: SafeArea(
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '▸ DETAIL',
                        style: mono.copyWith(
                          color: colors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: colors.textDim, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: colors.border),

              // ── Scrollable sections ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── CONV STATS ──
                      _SectionHeader(
                        title: 'CONV STATS',
                        expanded: _statsExpanded,
                        onTap: () => setState(
                            () => _statsExpanded = !_statsExpanded),
                        colors: colors,
                        mono: mono,
                      ),
                      if (_statsExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Messages',
                                value:
                                    '${chatState.messages.length}',
                                colors: colors,
                                mono: mono,
                              ),
                              _InfoRow(
                                label: 'Status',
                                value: chatState.isLoading
                                    ? 'STREAMING'
                                    : 'IDLE',
                                colors: colors,
                                mono: mono,
                                valueColor: chatState.isLoading
                                    ? colors.accent
                                    : null,
                              ),
                              if (chatState.totalInputTokens > 0 ||
                                  chatState.totalOutputTokens > 0) ...[
                                _InfoRow(
                                  label: 'In Tok',
                                  value: _formatTokenCount(chatState.totalInputTokens),
                                  colors: colors,
                                  mono: mono,
                                ),
                                _InfoRow(
                                  label: 'Out Tok',
                                  value: _formatTokenCount(chatState.totalOutputTokens),
                                  colors: colors,
                                  mono: mono,
                                ),
                                _InfoRow(
                                  label: 'Total',
                                  value: _formatTokenCount(
                                    chatState.totalInputTokens + chatState.totalOutputTokens,
                                  ),
                                  colors: colors,
                                  mono: mono,
                                  valueColor: colors.accent,
                                ),
                              ],
                            ],
                          ),
                        ),
                      Container(
                        height: 1,
                        color: colors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),

                      // ── PARAMETERS ──
                      _ParametersHeader(
                        expanded: _paramsExpanded,
                        onToggle: () => setState(
                            () => _paramsExpanded = !_paramsExpanded),
                        colors: colors,
                        mono: mono,
                      ),
                      if (_paramsExpanded)
                        Opacity(
                          opacity: sendParams ? 1.0 : 0.35,
                          child: IgnorePointer(
                            ignoring: !sendParams,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Column(
                                children: [
                                  _CompactSlider(
                                    label: 'Temp',
                                    value: temperature,
                                    min: 0.0,
                                    max: 2.0,
                                    divisions: 20,
                                    format: (v) =>
                                        v.toStringAsFixed(1),
                                    onChanged: (v) =>
                                        saveTemperature(ref, v),
                                    colors: colors,
                                    mono: mono,
                                  ),
                                  _CompactSlider(
                                    label: 'Top-K',
                                    value: topK.toDouble(),
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    format: (v) =>
                                        v.toInt().toString(),
                                    onChanged: (v) =>
                                        saveTopK(ref, v.toInt()),
                                    colors: colors,
                                    mono: mono,
                                  ),
                                  _CompactSlider(
                                    label: 'Top-P',
                                    value: topP,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    format: (v) =>
                                        v.toStringAsFixed(2),
                                    onChanged: (v) =>
                                        saveTopP(ref, v),
                                    colors: colors,
                                    mono: mono,
                                  ),
                                  _CompactSlider(
                                    label: 'Repeat',
                                    value: repeatPenalty,
                                    min: 0.0,
                                    max: 2.0,
                                    divisions: 20,
                                    format: (v) =>
                                        v.toStringAsFixed(1),
                                    onChanged: (v) =>
                                        saveRepeatPenalty(ref, v),
                                    colors: colors,
                                    mono: mono,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Container(
                        height: 1,
                        color: colors.border,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),

                      // ── TOOLS ──
                      _SectionHeader(
                        title: 'TOOLS',
                        expanded: _toolsExpanded,
                        onTap: () => setState(
                            () => _toolsExpanded = !_toolsExpanded),
                        colors: colors,
                        mono: mono,
                      ),
                      if (_toolsExpanded)
                        const ToolSettingsPanel(isDrawer: false),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────

/// Collapsible section header with ▸/▾ caret.
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final CyberTermColors colors;
  final TextStyle mono;

  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Text(
          '${expanded ? '▾' : '▸'} $title',
          style: mono.copyWith(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// Parameters header with collapse toggle + [ON]/[OFF] + [RST].
class _ParametersHeader extends ConsumerWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final CyberTermColors colors;
  final TextStyle mono;

  const _ParametersHeader({
    required this.expanded,
    required this.onToggle,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendParams = ref.watch(sendParametersProvider);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Row(
          children: [
            Flexible(
              child: Text(
                '${expanded ? '▾' : '▸'} PARAMETERS',
                style: mono.copyWith(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                saveSendParameters(ref, !sendParams);
              },
              child: Text(
                sendParams ? '[ON]' : '[OFF]',
                style: mono.copyWith(
                  color: sendParams ? colors.primary : colors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                saveTemperature(ref, 0.7);
                saveTopK(ref, 40);
                saveTopP(ref, 0.9);
                saveRepeatPenalty(ref, 1.1);
              },
              child: Text(
                '[RST]',
                style: mono.copyWith(
                  color: colors.textDim,
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

/// Compact key → value label row.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final CyberTermColors colors;
  final TextStyle mono;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.mono,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: mono.copyWith(color: colors.textDim, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono.copyWith(
                color: valueColor ?? colors.textColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Format token count with K suffix for large numbers.
String _formatTokenCount(int count) {
  if (count == 0) return '—';
  if (count >= 10000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

/// Compact parameter slider matching desktop DetailPanel styling.
class _CompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final CyberTermColors colors;
  final TextStyle mono;

  const _CompactSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: mono.copyWith(color: colors.textDim, fontSize: 10),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: colors.primary,
                inactiveTrackColor: colors.border,
                thumbColor: colors.primary,
                overlayColor: colors.primary.withOpacity(0.12),
                trackHeight: 2.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              format(value),
              style: mono.copyWith(color: colors.textColor, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
