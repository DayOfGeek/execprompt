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

/// Right-side detail panel for DESKTOP tier (>1200dp).
/// Collapsible sections: conv stats, parameters, tools, thinking.
class DetailPanel extends ConsumerStatefulWidget {
  const DetailPanel({super.key});

  @override
  ConsumerState<DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<DetailPanel> {
  bool _statsExpanded = true;
  bool _paramsExpanded = true;
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

    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: SafeArea(
          left: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 120) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Scrollable upper portion ──
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── CONV STATS ──
                          _CollapsibleHeader(
                            title: 'CONV STATS',
                            expanded: _statsExpanded,
                            onTap: () => setState(() =>
                                _statsExpanded = !_statsExpanded),
                            colors: colors,
                            mono: mono,
                          ),
                          if (_statsExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Column(
                                children: [
                                  _StatRow(
                                    label: 'Messages',
                                    value:
                                        '${chatState.messages.length}',
                                    colors: colors,
                                    mono: mono,
                                  ),
                                  _StatRow(
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
                                    _StatRow(
                                      label: 'In Tok',
                                      value: _formatTokenCount(chatState.totalInputTokens),
                                      colors: colors,
                                      mono: mono,
                                    ),
                                    _StatRow(
                                      label: 'Out Tok',
                                      value: _formatTokenCount(chatState.totalOutputTokens),
                                      colors: colors,
                                      mono: mono,
                                    ),
                                    _StatRow(
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
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4)),

                          // ── PARAMETERS ──
                          _ParametersCollapsibleHeader(
                            expanded: _paramsExpanded,
                            onToggle: () => setState(() =>
                                _paramsExpanded = !_paramsExpanded),
                            colors: colors,
                            mono: mono,
                          ),
                          if (_paramsExpanded)
                            Consumer(builder: (context, ref, _) {
                              final sendParams =
                                  ref.watch(sendParametersProvider);
                              return Opacity(
                                opacity: sendParams ? 1.0 : 0.35,
                                child: IgnorePointer(
                                  ignoring: !sendParams,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Column(
                                      children: [
                                        _ParamSlider(
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
                                        _ParamSlider(
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
                                        _ParamSlider(
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
                                        _ParamSlider(
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
                              );
                            }),
                          Container(
                              height: 1,
                              color: colors.border,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4)),

                          // ── TOOLS ──
                          _CollapsibleHeader(
                            title: 'TOOLS',
                            expanded: _toolsExpanded,
                            onTap: () => setState(() =>
                                _toolsExpanded = !_toolsExpanded),
                            colors: colors,
                            mono: mono,
                          ),
                          if (_toolsExpanded)
                            const ToolSettingsPanel(isDrawer: false),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Collapsible section header with ▸/▾ caret toggle.
class _CollapsibleHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final CyberTermColors colors;
  final TextStyle mono;

  const _CollapsibleHeader({
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final CyberTermColors colors;
  final TextStyle mono;
  final Color? valueColor;

  const _StatRow({
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
            child: Text(label, style: mono.copyWith(color: colors.textDim, fontSize: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: mono.copyWith(color: valueColor ?? colors.textColor, fontSize: 11),
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

// ── Parameters collapsible header with ▸/▾ + [ON]/[OFF] + [RST] ────

class _ParametersCollapsibleHeader extends ConsumerWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final CyberTermColors colors;
  final TextStyle mono;

  const _ParametersCollapsibleHeader({
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

// ── Compact parameter slider ────────────────────────────────────────

class _ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final CyberTermColors colors;
  final TextStyle mono;

  const _ParamSlider({
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
                overlayColor: colors.primary.withValues(alpha: 0.12),
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
