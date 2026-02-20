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
import 'package:google_fonts/google_fonts.dart';
import '../../domain/providers/chat_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Pulsing status line shown below the chat messages during web search.
/// Appears only when [ChatState.searchStatus] is non-null.
class SearchStatusIndicator extends ConsumerWidget {
  const SearchStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchStatus = ref.watch(
      chatProvider.select((s) => s.searchStatus),
    );

    if (searchStatus == null) return const SizedBox.shrink();

    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
        ),
        color: colors.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          _PulsingDot(color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              searchStatus,
              style: mono.copyWith(
                color: colors.primaryDim,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dot.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3 + _controller.value * 0.7),
          ),
        );
      },
    );
  }
}
