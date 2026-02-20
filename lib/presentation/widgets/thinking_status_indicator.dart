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


import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/providers/chat_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Compact cyberpunk status bar shown when the model is actively reasoning.
///
/// Single-line animated indicator: braille spinner, block-char sweep wave,
/// cycling hex data-stream, character count. No text excerpt — the full
/// thinking stream is viewable in the chat bubble's REASONING fold.
class ThinkingStatusIndicator extends ConsumerStatefulWidget {
  const ThinkingStatusIndicator({super.key});

  @override
  ConsumerState<ThinkingStatusIndicator> createState() =>
      _ThinkingStatusIndicatorState();
}

class _ThinkingStatusIndicatorState
    extends ConsumerState<ThinkingStatusIndicator> {
  Timer? _animTimer;
  int _frame = 0;
  final _rng = Random();

  static const _spinnerFrames = [
    '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏',
  ];
  static const _waveChars = ['░', '▒', '▓', '█', '▓', '▒', '░', ' '];
  static const _hexDigits = '0123456789ABCDEF';

  void _syncTimer(bool active) {
    if (active && _animTimer == null) {
      _animTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (mounted) setState(() => _frame++);
        },
      );
    } else if (!active && _animTimer != null) {
      _animTimer!.cancel();
      _animTimer = null;
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  String _buildWave() =>
      List.generate(8, (i) => _waveChars[(_frame + i) % _waveChars.length])
          .join();

  String _buildHex() =>
      List.generate(6, (_) => _hexDigits[_rng.nextInt(16)]).join();

  String _fmtChars(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final thinking = ref.watch(
      chatProvider.select((s) => s.currentStreamingThinking),
    );
    final isLoading = ref.watch(
      chatProvider.select((s) => s.isLoading),
    );

    final active = thinking != null && thinking.isNotEmpty && isLoading;
    _syncTimer(active);
    if (!active) return const SizedBox.shrink();

    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.primary.withValues(alpha: 0.25)),
        ),
        color: colors.primary.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Text(
            _spinnerFrames[_frame % _spinnerFrames.length],
            style: mono.copyWith(color: colors.primary, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            _buildWave(),
            style: mono.copyWith(
              color: colors.primary.withValues(alpha: 0.35),
              fontSize: 7,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'REASONING',
            style: mono.copyWith(
              color: colors.primary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '0x${_buildHex()}',
            style: mono.copyWith(
              color: colors.primaryDim.withValues(alpha: 0.4),
              fontSize: 8,
            ),
          ),
          const Spacer(),
          Text(
            '${_fmtChars(thinking.length)} chars',
            style: mono.copyWith(color: colors.textDim, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
