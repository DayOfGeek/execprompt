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

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import 'blinking_cursor.dart';
import 'code_block_builder.dart';

class MessageBubble extends StatelessWidget {
  final String role;
  final String? content;
  final String? thinking;
  final DateTime? timestamp;
  final bool isStreaming;
  final List<String>? images;
  final List<String>? sourceUrls;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onFork;
  final bool isError;

  const MessageBubble({
    super.key,
    required this.role,
    this.content,
    this.thinking,
    this.timestamp,
    this.isStreaming = false,
    this.images,
    this.sourceUrls,
    this.onRetry,
    this.onDelete,
    this.onEdit,
    this.onFork,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    final String tag = isUser ? 'USR' : 'SYS';
    final Color tagColor = isUser ? colors.accent : colors.primary;
    final Color bubbleBg = isError
        ? colors.error.withOpacity(0.1)
        : isUser
            ? colors.userBubble
            : colors.botBubble;
    final Color borderColor = isError ? colors.error : colors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bubbleBg,
          border: Border(
            left: BorderSide(color: tagColor, width: 2),
            top: BorderSide(color: borderColor, width: 0.5),
            bottom: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: [USR]/[SYS] + timestamp + actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    '[$tag]',
                    style: mono.copyWith(
                      color: tagColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp!),
                      style: mono.copyWith(color: colors.textDim, fontSize: 10),
                    ),
                  const Spacer(),
                  if (!isStreaming && content != null && content!.isNotEmpty)
                    _TermAction(
                      label: 'CP',
                      color: colors.textDim,
                      mono: mono,
                      onTap: () => _copyToClipboard(context),
                    ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 6),
                    _TermAction(
                      label: 'ED',
                      color: colors.primaryDim,
                      mono: mono,
                      onTap: onEdit!,
                    ),
                  ],
                  if (onFork != null) ...[
                    const SizedBox(width: 6),
                    _TermAction(
                      label: 'FK',
                      color: colors.primaryDim,
                      mono: mono,
                      onTap: () => _confirmFork(context, colors, mono),
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(width: 6),
                    _TermAction(
                      label: 'RT',
                      color: colors.accent,
                      mono: mono,
                      onTap: onRetry!,
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 6),
                    _TermAction(
                      label: 'RM',
                      color: colors.error,
                      mono: mono,
                      onTap: () => _confirmDelete(context, colors, mono),
                    ),
                  ],
                ],
              ),
            ),

            // Thinking section (collapsible, animated when streaming)
            if (thinking != null && thinking!.isNotEmpty)
              _ThinkingSection(
                thinking: thinking!,
                isStreaming: isStreaming,
                colors: colors,
                mono: mono,
              ),

            // Image attachments
            if (images != null && images!.isNotEmpty)
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images!.map((img) {
                      try {
                        final bytes = base64Decode(img);
                        return ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.border),
                            ),
                            child: Image.memory(
                              bytes,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        );
                      } catch (_) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            color: colors.surface,
                          ),
                          child:
                              Icon(Icons.broken_image, color: colors.textDim),
                        );
                      }
                    }).toList(),
                  ),
                ),
              ),

            // Content
            if (content != null && content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: isUser || isStreaming
                    // Plain text during streaming to avoid flutter_markdown
                    // _inlines.isEmpty assertion on incomplete inline md.
                    // Rich markdown is rendered once the stream completes.
                    ? SelectableText(
                        content!,
                        style: mono.copyWith(
                          color: colors.textColor,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      )
                    : _SafeMarkdown(
                        data: content!,
                        colors: colors,
                        mono: mono,
                      ),
              )
            else if (isStreaming && (content == null || content!.isEmpty))
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '> ',
                      style:
                          mono.copyWith(color: colors.primaryDim, fontSize: 13),
                    ),
                    BlinkingCursor(color: colors.primary, fontSize: 13),
                  ],
                ),
              ),

            // Streaming cursor at end of content
            if (isStreaming && content != null && content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 8),
                child: BlinkingCursor(color: colors.primary, fontSize: 13),
              ),

            // Source citations (from web search)
            if (sourceUrls != null && sourceUrls!.isNotEmpty && !isStreaming)
              _SourceCitations(
                urls: sourceUrls!,
                colors: colors,
                mono: mono,
              ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: content ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('> Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _confirmFork(
      BuildContext context, CyberTermColors colors, TextStyle mono) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          '▸ FORK CONVERSATION',
          style: mono.copyWith(
              color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Create a new conversation branching from this message? '
          'All messages up to this point will be copied.',
          style: mono.copyWith(color: colors.textDim, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('[CANCEL]',
                style: mono.copyWith(color: colors.textDim, fontSize: 11)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onFork!();
            },
            child: Text('[FORK]',
                style: mono.copyWith(color: colors.primary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CyberTermColors colors, TextStyle mono) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          '▸ DELETE MESSAGE',
          style: mono.copyWith(
              color: colors.error, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove this message from the conversation? This cannot be undone.',
          style: mono.copyWith(color: colors.textDim, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('[CANCEL]',
                style: mono.copyWith(color: colors.textDim, fontSize: 11)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete!();
            },
            child: Text('[DELETE]',
                style: mono.copyWith(color: colors.error, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Collapsible thinking section with animated cyberpunk glow.
///
/// When [isStreaming] is true, the header pulses with a neon glow animation
/// to make it obvious the model is actively reasoning. When complete, the
/// glow fades to a static but visible state, inviting the user to expand.
class _ThinkingSection extends StatefulWidget {
  final String thinking;
  final bool isStreaming;
  final CyberTermColors colors;
  final TextStyle mono;

  const _ThinkingSection({
    required this.thinking,
    required this.isStreaming,
    required this.colors,
    required this.mono,
  });

  @override
  State<_ThinkingSection> createState() => _ThinkingSectionState();
}

class _ThinkingSectionState extends State<_ThinkingSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Braille spinner frames for active reasoning
  static const _spinnerFrames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isStreaming) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ThinkingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isStreaming && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatChars(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final spinIdx = widget.isStreaming
        ? (DateTime.now().millisecondsSinceEpoch ~/ 100) % _spinnerFrames.length
        : 0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glowAlpha = widget.isStreaming ? _pulse.value : 0.12;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colors.primary.withOpacity(glowAlpha),
                      widget.colors.primary.withOpacity(glowAlpha * 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.colors.primary.withOpacity(
                        widget.isStreaming
                            ? math.min(0.6, glowAlpha + 0.2)
                            : 0.2,
                      ),
                      width: widget.isStreaming ? 1.0 : 0.5,
                    ),
                    left: BorderSide(
                      color: widget.colors.primary.withOpacity(
                        widget.isStreaming ? 0.8 : 0.3,
                      ),
                      width: 2,
                    ),
                  ),
                  boxShadow: widget.isStreaming
                      ? [
                          BoxShadow(
                            color: widget.colors.primary
                                .withOpacity(glowAlpha * 0.5),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Braille spinner (streaming) or caret (static)
                    if (widget.isStreaming)
                      Text(
                        _spinnerFrames[spinIdx],
                        style: widget.mono.copyWith(
                          color: widget.colors.primary,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        _expanded ? '▾' : '▸',
                        style: widget.mono.copyWith(
                          color: widget.colors.primary,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'REASONING',
                      style: widget.mono.copyWith(
                        color: widget.colors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (widget.isStreaming) ...[
                      const SizedBox(width: 6),
                      BlinkingCursor(
                        color: widget.colors.primary,
                        fontSize: 10,
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      Text(
                        '[TAP]',
                        style: widget.mono.copyWith(
                          color: widget.colors.primaryDim.withOpacity(0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${_formatChars(widget.thinking.length)} chars',
                      style: widget.mono.copyWith(
                        color: widget.colors.textDim,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                padding: const EdgeInsets.all(10),
                color: widget.colors.primary.withOpacity(0.05),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    widget.thinking,
                    style: widget.mono.copyWith(
                      color: widget.colors.textDim,
                      fontSize: 11,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Terminal-style inline action button [XX]
class _TermAction extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle mono;
  final VoidCallback onTap;

  const _TermAction({
    required this.label,
    required this.color,
    required this.mono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        '[$label]',
        style: mono.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Renders tappable source URLs from web search results.
class _SourceCitations extends StatelessWidget {
  final List<String> urls;
  final CyberTermColors colors;
  final TextStyle mono;

  const _SourceCitations({
    required this.urls,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
        color: colors.primary.withOpacity(0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sources:',
            style: mono.copyWith(
              color: colors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          ...urls.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final url = entry.value;
            final displayUrl = _shortenUrl(url);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: InkWell(
                onTap: () => _launchUrl(url),
                child: Text(
                  '[$index] $displayUrl',
                  style: mono.copyWith(
                    color: colors.accent,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.accent.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path =
          uri.path.length > 40 ? '${uri.path.substring(0, 40)}...' : uri.path;
      return '${uri.host}$path';
    } catch (_) {
      return url.length > 60 ? '${url.substring(0, 60)}...' : url;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Markdown rendering ──────────────────────────────────────────────

/// Renders completed assistant messages as rich markdown using
/// [markdown_widget] package (replaces flutter_markdown which had the
/// `_inlines.isEmpty` assertion crash on widget rebuilds).
/// Only used for non-streaming content — during streaming we use plain
/// [SelectableText] to avoid assertion/render errors on incomplete
/// inline formatting.
class _SafeMarkdown extends StatelessWidget {
  final String data;
  final CyberTermColors colors;
  final TextStyle mono;

  const _SafeMarkdown({
    required this.data,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MarkdownBlock(
        data: data,
        selectable: true,
        config: MarkdownConfig(configs: [
          PConfig(
              textStyle: mono.copyWith(
            color: colors.textColor,
            fontSize: 13,
            height: 1.5,
          )),
          CodeConfig(
              style: mono.copyWith(
            color: colors.accent,
            fontSize: 12,
            backgroundColor: colors.surface,
          )),
          terminalPreConfig(colors),
          H1Config(
              style: mono.copyWith(
            color: colors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          )),
          H2Config(
              style: mono.copyWith(
            color: colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )),
          H3Config(
              style: mono.copyWith(
            color: colors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          )),
          BlockquoteConfig(
            sideColor: colors.primaryDim,
            textColor: colors.textDim,
            sideWith: 2.0,
            padding: const EdgeInsets.only(left: 10),
          ),
          LinkConfig(
            style: mono.copyWith(
              color: colors.accent,
              decoration: TextDecoration.underline,
            ),
            onTap: (url) async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          TableConfig(
            border: TableBorder.all(color: colors.border, width: 0.5),
            headerStyle: mono.copyWith(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            bodyStyle: mono.copyWith(
              color: colors.textColor,
              fontSize: 12,
            ),
          ),
        ]),
      ),
    );
  }
}
