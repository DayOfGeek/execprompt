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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/database/app_database.dart';
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/database_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Inline conversation panel used as a persistent sidebar on tablet/desktop.
/// Shares the same content logic as ConversationDrawer but renders inline
/// without the Drawer wrapper and without Navigator.pop() calls.
class ConversationPanel extends ConsumerStatefulWidget {
  const ConversationPanel({super.key});

  @override
  ConsumerState<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<ConversationPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    final conversations = ref.watch(filteredConversationsProvider);
    final currentId = ref.watch(currentConversationIdProvider);

    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colors.border, width: 1),
          ),
        ),
        child: SafeArea(
          right: false,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '▸ CONVERSATIONS',
                style: mono.copyWith(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(height: 1, color: colors.border),

            // New Chat button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(chatProvider.notifier).newChat();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '+ ',
                      style: mono.copyWith(
                        color: colors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'New Chat',
                      style: mono.copyWith(
                        color: colors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: colors.border),

            // Search
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                style: mono.copyWith(color: colors.textColor, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '/ search...',
                  hintStyle: mono.copyWith(color: colors.textDim, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 16, color: colors.textDim),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  ref.read(conversationSearchQueryProvider.notifier).state = value;
                },
              ),
            ),

            // Conversation list
            Expanded(
              child: conversations.when(
                data: (convos) {
                  if (convos.isEmpty) {
                    return Center(
                      child: Text(
                        _searchController.text.isNotEmpty
                            ? '> No results'
                            : '> No conversations yet',
                        style: mono.copyWith(color: colors.textDim, fontSize: 12),
                      ),
                    );
                  }
                  final grouped = _groupByDate(convos);
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: grouped.entries.expand<Widget>((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: mono.copyWith(
                              color: colors.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...entry.value.map((convo) {
                          final isActive = convo.id == currentId;
                          return _PanelConversationTile(
                            conversation: convo,
                            isActive: isActive,
                            colors: colors,
                            mono: mono,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(chatProvider.notifier).loadConversation(convo.id);
                            },
                            onDelete: () => _confirmDelete(context, convo),
                            onRename: () => _showRename(context, convo),
                            onExport: () => _exportConversation(context, convo),
                          );
                        }),
                      ];
                    }).toList(),
                  );
                },
                loading: () => Center(
                  child: Text('> Loading...', style: mono.copyWith(color: colors.textDim, fontSize: 12)),
                ),
                error: (e, _) => Center(
                  child: Text('> Error: $e', style: mono.copyWith(color: colors.error, fontSize: 12)),
                ),
              ),
            ),

            Container(height: 1, color: colors.border),

            // Bottom navigation
            InkWell(
              onTap: () => context.push('/models'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.storage, size: 16, color: colors.primaryDim),
                    const SizedBox(width: 8),
                    Text('Models', style: mono.copyWith(color: colors.textDim, fontSize: 12)),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => context.push('/settings'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 16, color: colors.primaryDim),
                    const SizedBox(width: 8),
                    Text('Settings', style: mono.copyWith(color: colors.textDim, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Map<String, List<Conversation>> _groupByDate(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = today.subtract(const Duration(days: 30));

    final Map<String, List<Conversation>> groups = {};

    for (final convo in conversations) {
      final date = DateTime(convo.updatedAt.year, convo.updatedAt.month, convo.updatedAt.day);
      String key;
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else if (date.isAfter(weekAgo)) {
        key = 'Previous 7 Days';
      } else if (date.isAfter(monthAgo)) {
        key = 'This Month';
      } else {
        key = 'Older';
      }
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(convo);
    }
    return groups;
  }

  void _confirmDelete(BuildContext context, Conversation convo) {
    final colors = Theme.of(context).cyberTermColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete "${convo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () {
              ref.read(chatProvider.notifier).deleteConversation(convo.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRename(BuildContext context, Conversation convo) {
    final controller = TextEditingController(text: convo.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Conversation title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(chatProvider.notifier).renameConversation(convo.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportConversation(BuildContext context, Conversation convo) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.pop(ctx);
                _doExport(context, convo, markdown: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as Markdown'),
              onTap: () {
                Navigator.pop(ctx);
                _doExport(context, convo, markdown: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doExport(BuildContext context, Conversation convo, {required bool markdown}) async {
    final mono = GoogleFonts.jetBrainsMono();
    final colors = Theme.of(context).cyberTermColors;
    try {
      final db = ref.read(databaseProvider);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final safeTitle = convo.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');

      if (markdown) {
        final md = await db.exportConversationAsMarkdown(convo.id);
        final file = File('${dir.path}/${safeTitle}_$timestamp.md');
        await file.writeAsString(md);
        await Share.shareXFiles([XFile(file.path)], subject: convo.title);
      } else {
        final data = await db.exportConversation(convo.id);
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
        final file = File('${dir.path}/${safeTitle}_$timestamp.json');
        await file.writeAsString(jsonStr);
        await Share.shareXFiles([XFile(file.path)], subject: convo.title);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('> Export ready', style: mono.copyWith(fontSize: 12))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('> Export failed: $e', style: mono.copyWith(fontSize: 12)),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

class _PanelConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final CyberTermColors colors;
  final TextStyle mono;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onExport;

  const _PanelConversationTile({
    required this.conversation,
    required this.isActive,
    required this.colors,
    required this.mono,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rename'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRename();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Export'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onExport();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: colors.error),
                  title: Text('Delete', style: TextStyle(color: colors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isActive ? colors.primary.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Text(
              isActive ? '▸ ' : '  ',
              style: mono.copyWith(
                color: isActive ? colors.primary : colors.textDim,
                fontSize: 12,
              ),
            ),
            Expanded(
              child: _PanelTileContent(
                conversation: conversation,
                isActive: isActive,
                colors: colors,
                mono: mono,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile content that shows a search snippet when a search query is active.
class _PanelTileContent extends ConsumerWidget {
  final Conversation conversation;
  final bool isActive;
  final CyberTermColors colors;
  final TextStyle mono;

  const _PanelTileContent({
    required this.conversation,
    required this.isActive,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(conversationSearchQueryProvider).trim();
    final snippetAsync = query.isNotEmpty
        ? ref.watch(searchSnippetProvider(conversation.id))
        : const AsyncValue<String?>.data(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mono.copyWith(
            color: isActive ? colors.primary : colors.textColor,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        // Search snippet — shows matching message excerpt when searching
        if (query.isNotEmpty)
          snippetAsync.when(
            data: (snippet) => snippet != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono.copyWith(
                        color: colors.accent.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        const SizedBox(height: 2),
        Text(
          '${conversation.modelName} · ${_formatDate(conversation.updatedAt)}',
          style: mono.copyWith(color: colors.textDim, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
