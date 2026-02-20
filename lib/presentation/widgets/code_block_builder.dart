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
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:markdown_widget/markdown_widget.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Builds a [PreConfig] for terminal-styled code blocks using CyberTerm theme.
/// Provides language header bar with [CP] copy button, syntax highlighting
/// via highlight.js port, and terminal-style container matching the theme.
PreConfig terminalPreConfig(CyberTermColors colors) {
  return PreConfig(
    // Use builder to completely replace default code block rendering
    // with our terminal-styled widget.
    builder: (code, language) => _TerminalCodeBlock(
      code: code.trimRight(),
      language: language.isNotEmpty ? language : null,
      colors: colors,
    ),
    // Suppress default decoration since our builder handles everything.
    decoration: const BoxDecoration(),
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
  );
}

/// Terminal-styled code block widget with syntax highlighting
class _TerminalCodeBlock extends StatelessWidget {
  final String code;
  final String? language;
  final CyberTermColors colors;

  const _TerminalCodeBlock({
    required this.code,
    this.language,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar: language + copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(color: colors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '▸ ${(language ?? 'code').toUpperCase()}',
                  style: mono.copyWith(
                    color: colors.primaryDim,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code, colors: colors, mono: mono),
              ],
            ),
          ),
          // Code content with syntax highlighting
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: _buildHighlightedCode(mono),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCode(TextStyle mono) {
    try {
      final result = language != null
          ? highlight.parse(code, language: language)
          : highlight.parse(code, autoDetection: true);

      final spans = _buildSpans(result.nodes ?? [], mono);
      return SelectableText.rich(
        TextSpan(children: spans),
        style: mono.copyWith(
          color: colors.textColor,
          fontSize: 12,
          height: 1.5,
        ),
      );
    } catch (_) {
      // Fallback: no highlighting
      return SelectableText(
        code,
        style: mono.copyWith(
          color: colors.textColor,
          fontSize: 12,
          height: 1.5,
        ),
      );
    }
  }

  List<TextSpan> _buildSpans(List<Node> nodes, TextStyle mono) {
    final spans = <TextSpan>[];
    final theme = _getTerminalHighlightTheme();

    for (final node in nodes) {
      if (node.value != null) {
        // Text node
        final className = node.className;
        final style = className != null ? theme[className] : null;
        spans.add(TextSpan(
          text: node.value,
          style: style ?? mono.copyWith(color: colors.textColor, fontSize: 12, height: 1.5),
        ));
      } else if (node.children != null) {
        // Element node with children — recursively build
        final className = node.className;
        final childSpans = _buildChildSpans(node.children!, className, mono, theme);
        spans.addAll(childSpans);
      }
    }
    return spans;
  }

  List<TextSpan> _buildChildSpans(
    List<Node> children,
    String? parentClass,
    TextStyle mono,
    Map<String, TextStyle> theme,
  ) {
    final spans = <TextSpan>[];
    final parentStyle = parentClass != null ? theme[parentClass] : null;

    for (final child in children) {
      if (child.value != null) {
        final className = child.className ?? parentClass;
        final style = className != null ? theme[className] : parentStyle;
        spans.add(TextSpan(
          text: child.value,
          style: style ?? mono.copyWith(color: colors.textColor, fontSize: 12, height: 1.5),
        ));
      } else if (child.children != null) {
        final className = child.className ?? parentClass;
        spans.addAll(_buildChildSpans(child.children!, className, mono, theme));
      }
    }
    return spans;
  }

  /// Generate a terminal-themed syntax highlighting palette from CyberTermColors
  Map<String, TextStyle> _getTerminalHighlightTheme() {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.5);

    return {
      // Keywords: if, else, for, while, return, class, function, etc.
      'keyword': mono.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
      'built_in': mono.copyWith(color: colors.primary),

      // Strings
      'string': mono.copyWith(color: colors.accent),
      'addition': mono.copyWith(color: colors.accent),

      // Numbers & literals
      'number': mono.copyWith(color: colors.accent),
      'literal': mono.copyWith(color: colors.accent),

      // Comments
      'comment': mono.copyWith(color: colors.textDim, fontStyle: FontStyle.italic),
      'doctag': mono.copyWith(color: colors.textDim),

      // Types / classes
      'type': mono.copyWith(color: colors.primary),
      'class': mono.copyWith(color: colors.primary),
      'title': mono.copyWith(color: colors.primary),
      'title.class_': mono.copyWith(color: colors.primary),
      'title.function_': mono.copyWith(color: colors.textColor),

      // Functions
      'function': mono.copyWith(color: colors.textColor),

      // Variables & params
      'variable': mono.copyWith(color: colors.textColor),
      'params': mono.copyWith(color: colors.textColor),
      'attr': mono.copyWith(color: colors.primaryDim),
      'attribute': mono.copyWith(color: colors.primaryDim),

      // Operators & punctuation
      'operator': mono.copyWith(color: colors.primaryDim),
      'punctuation': mono.copyWith(color: colors.textDim),

      // Meta / preprocessor
      'meta': mono.copyWith(color: colors.primaryDim),
      'meta-keyword': mono.copyWith(color: colors.primaryDim, fontWeight: FontWeight.bold),
      'meta-string': mono.copyWith(color: colors.accent),

      // Regex
      'regexp': mono.copyWith(color: colors.accent),

      // Tags (HTML/XML)
      'tag': mono.copyWith(color: colors.primary),
      'name': mono.copyWith(color: colors.primary),

      // Symbols
      'symbol': mono.copyWith(color: colors.accent),
      'bullet': mono.copyWith(color: colors.primaryDim),

      // Links
      'link': mono.copyWith(color: colors.accent, decoration: TextDecoration.underline),

      // Emphasis
      'emphasis': mono.copyWith(fontStyle: FontStyle.italic),
      'strong': mono.copyWith(fontWeight: FontWeight.bold),

      // Deletion (diff)
      'deletion': mono.copyWith(color: colors.error),

      // Section headers
      'section': mono.copyWith(color: colors.primary, fontWeight: FontWeight.bold),

      // Template
      'template-variable': mono.copyWith(color: colors.accent),
      'template-tag': mono.copyWith(color: colors.primaryDim),

      // Selector (CSS)
      'selector-tag': mono.copyWith(color: colors.primary),
      'selector-id': mono.copyWith(color: colors.accent),
      'selector-class': mono.copyWith(color: colors.primaryDim),
      'selector-attr': mono.copyWith(color: colors.primaryDim),
      'selector-pseudo': mono.copyWith(color: colors.primaryDim),

      // Subst
      'subst': mono.copyWith(color: colors.textColor),
    };
  }
}

/// Terminal-styled copy button [CP]
class _CopyButton extends StatefulWidget {
  final String code;
  final CyberTermColors colors;
  final TextStyle mono;

  const _CopyButton({
    required this.code,
    required this.colors,
    required this.mono,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _handleCopy() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleCopy,
      child: Text(
        _copied ? '[OK]' : '[CP]',
        style: widget.mono.copyWith(
          color: _copied ? widget.colors.accent : widget.colors.textDim,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
