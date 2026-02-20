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
import '../../data/database/app_database.dart';
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/database_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import '../responsive/breakpoints.dart';
import '../widgets/conversation_panel.dart';
import '../widgets/detail_panel.dart';
import '../widgets/mobile_detail_drawer.dart';
import '../widgets/model_picker.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/prompt_suggestions.dart';
import '../widgets/search_status_indicator.dart';
import '../widgets/thinking_status_indicator.dart';
import '../../data/models/ollama_error.dart';

/// Adaptive shell that renders three layout tiers:
///   PHONE:   current ChatScreen (drawer, full-width)
///   TABLET:  sidebar + chat area (2 columns)
///   DESKTOP: sidebar + chat area + detail panel (3 columns)
class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key});

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _showScrollToBottom = false;
  bool _detailPanelCollapsed = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final isNearBottom = _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        200;
    if (_showScrollToBottom == isNearBottom) {
      setState(() => _showScrollToBottom = !isNearBottom);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _fillPrompt(String prompt) {
    ref.read(chatProvider.notifier).sendMessage(prompt);
  }

  void _handleEdit(String messageId) {
    final content = ref.read(chatProvider.notifier).editMessageAt(messageId);
    if (content != null && content.isNotEmpty) {
      HapticFeedback.lightImpact();
      _inputController.text = content;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: content.length),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Escape → Stop generation
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final chatState = ref.read(chatProvider);
      if (chatState.isLoading) {
        HapticFeedback.mediumImpact();
        ref.read(chatProvider.notifier).stopGeneration();
        return KeyEventResult.handled;
      }
    }

    // Ctrl+N → New chat
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyN) {
      HapticFeedback.lightImpact();
      ref.read(chatProvider.notifier).newChat();
      return KeyEventResult.handled;
    }

    // Ctrl+, → Settings
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.comma) {
      context.push('/settings');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.layoutTier;
    final sizes = context.responsiveSizes;
    final chatState = ref.watch(chatProvider);
    final selectedModel = ref.watch(selectedModelProvider);
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    // Auto-scroll on new messages
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.currentStreamingContent != next.currentStreamingContent) {
        _scrollToBottom();
      }
    });

    final chatArea = _buildChatArea(
      context, chatState, selectedModel, colors, mono, sizes, tier,
    );

    Widget body;
    if (tier.showSidebar) {
      // TABLET-L or DESKTOP: multi-column layout
      body = Row(
        children: [
          SizedBox(
            width: sizes.sidebarWidth,
            child: const ConversationPanel(),
          ),
          Expanded(child: chatArea),
          if (tier.showDetailPanel)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _detailPanelCollapsed ? 0 : sizes.detailPanelWidth,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: _detailPanelCollapsed
                  ? const SizedBox.shrink()
                  : const DetailPanel(),
            ),
        ],
      );
    } else {
      // PHONE or TABLET-S: single column (current layout)
      body = chatArea;
    }

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: body,
    );
  }

  Widget _buildChatArea(
    BuildContext context,
    ChatState chatState,
    String? selectedModel,
    CyberTermColors colors,
    TextStyle mono,
    ResponsiveSizes sizes,
    LayoutTier tier,
  ) {
    return Scaffold(
      // Only show drawer on phone/tablet-small (no persistent sidebar)
      drawer: tier.showSidebar ? null : const _PhoneDrawerWrapper(),
      // Detail drawer on the right — shown on tiers without the persistent detail panel
      endDrawer: tier.showDetailPanel ? null : const MobileDetailDrawer(),
      appBar: _buildAppBar(context, chatState, selectedModel, colors, mono, tier),
      body: Stack(
        children: [
          Column(
            children: [
              // Model warning
              if (selectedModel == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.error.withValues(alpha: 0.3)),
                    ),
                    color: colors.error.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Text('! ',
                          style: mono.copyWith(
                              color: colors.error,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          'No model selected',
                          style: mono.copyWith(color: colors.error, fontSize: 12),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/models'),
                        child: Text(
                          '[SELECT]',
                          style: mono.copyWith(
                            color: colors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Chat content
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isLoading
                    ? PromptSuggestions(
                        selectedModel: ref.watch(selectedModelDisplayProvider),
                        isServerConfigured: ref.watch(isServerConfiguredProvider),
                        onPromptTap: _fillPrompt,
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _detailPanelCollapsed
                                ? (sizes.chatMaxWidth != null ? sizes.chatMaxWidth! + sizes.detailPanelWidth : double.infinity)
                                : (sizes.chatMaxWidth ?? double.infinity),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: sizes.contentPadding,
                              vertical: 8,
                            ),
                            itemCount: chatState.messages.length +
                                (chatState.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == chatState.messages.length &&
                                  chatState.isLoading) {
                                return MessageBubble(
                                  role: 'assistant',
                                  content: chatState.currentStreamingContent,
                                  thinking: chatState.currentStreamingThinking,
                                  isStreaming: true,
                                );
                              }

                              final message = chatState.messages[index];
                              final isLastAssistant =
                                  message.message.role == 'assistant' &&
                                      index == chatState.messages.length - 1;
                              final isUser = message.message.role == 'user';

                              return MessageBubble(
                                key: ValueKey(message.id),
                                role: message.message.role,
                                content: message.message.content,
                                thinking: message.message.thinking,
                                timestamp: message.timestamp,
                                images: message.message.images,
                                isError: message.isError,
                                onEdit: isUser && !chatState.isLoading
                                    ? () => _handleEdit(message.id)
                                    : null,
                                onFork: !chatState.isLoading
                                    ? () => ref
                                        .read(chatProvider.notifier)
                                        .forkConversation(message.id)
                                    : null,
                                onRetry: isLastAssistant
                                    ? () => ref
                                        .read(chatProvider.notifier)
                                        .retryLastMessage()
                                    : null,
                                onDelete: () => ref
                                    .read(chatProvider.notifier)
                                    .removeMessage(message.id),
                              );
                            },
                          ),
                        ),
                      ),
              ),

              // Error bar
              if (chatState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.error.withValues(alpha: 0.3)),
                    ),
                    color: colors.error.withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Text('✕ ',
                          style: mono.copyWith(color: colors.error, fontSize: 14)),
                      Expanded(
                        child: Text(
                          chatState.error!.userMessage,
                          style: mono.copyWith(color: colors.error, fontSize: 11),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref
                            .read(chatProvider.notifier)
                            .retryLastMessage(),
                        child: Text(
                          '[RETRY]',
                          style: mono.copyWith(
                              color: colors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Thinking status indicator (cyberpunk animation)
              const ThinkingStatusIndicator(),

              // Search status indicator
              const SearchStatusIndicator(),

              // Input
              ChatInput(
                enabled: selectedModel != null && !chatState.isLoading,
                isLoading: chatState.isLoading,
                externalController: _inputController,
                onSend: (message, {List<String>? images}) {
                  HapticFeedback.lightImpact();
                  ref
                      .read(chatProvider.notifier)
                      .sendMessage(message, images: images);
                },
                onStopGeneration: chatState.isLoading
                    ? () {
                        HapticFeedback.mediumImpact();
                        ref.read(chatProvider.notifier).stopGeneration();
                      }
                    : null,
              ),
            ],
          ),

          // Scroll-to-bottom button
          if (_showScrollToBottom && chatState.messages.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 80,
              child: InkWell(
                onTap: _scrollToBottom,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: colors.primary, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatState chatState,
    String? selectedModel,
    CyberTermColors colors,
    TextStyle mono,
    LayoutTier tier,
  ) {
    return AppBar(
      // On tablet with sidebar, no hamburger menu needed
      leading: tier.showSidebar
          ? null
          : Builder(
              builder: (context) => IconButton(
                icon: Text('☰',
                    style: mono.copyWith(color: colors.primary, fontSize: 20)),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Conversations',
              ),
            ),
      automaticallyImplyLeading: !tier.showSidebar,
      title: Row(
        children: [
          if (!tier.showSidebar)
            Text(
              'ExecPrompt',
              style: mono.copyWith(
                color: colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (tier.showSidebar)
            Text(
              '▸ CHAT',
              style: mono.copyWith(
                color: colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (selectedModel != null) ...[
            Text(' │ ',
                style: mono.copyWith(color: colors.border, fontSize: 14)),
            Expanded(
              child: InkWell(
                onTap: () => showMultiModelPicker(context, ref),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        ref.watch(selectedModelDisplayProvider) ?? selectedModel,
                        style: mono.copyWith(color: colors.textDim, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 16, color: colors.textDim),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (chatState.messages.isNotEmpty)
          IconButton(
            icon: Icon(Icons.add, color: colors.primary, size: 20),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(chatProvider.notifier).newChat();
            },
            tooltip: 'New chat',
          ),
        // Detail drawer button — visible when detail panel is not shown
        if (!tier.showDetailPanel)
          Builder(
            builder: (context) {
              final webSearchOn = ref.watch(webSearchEnabledProvider);
              final paramsOn = ref.watch(sendParametersProvider);
              return IconButton(
                icon: Icon(
                  Icons.tune,
                  color: (webSearchOn || paramsOn)
                      ? colors.primary
                      : colors.primaryDim,
                  size: 20,
                ),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: 'Detail panel',
              );
            },
          ),
        if (tier.showDetailPanel)
          IconButton(
            icon: Icon(
              _detailPanelCollapsed
                  ? Icons.vertical_split_outlined
                  : Icons.vertical_split,
              color: colors.primaryDim,
              size: 20,
            ),
            onPressed: () {
              setState(() => _detailPanelCollapsed = !_detailPanelCollapsed);
            },
            tooltip: _detailPanelCollapsed ? 'Show detail panel' : 'Hide detail panel',
          ),
      ],
    );
  }
}

/// Wrapper that provides the ConversationDrawer as a phone-sized Drawer.
/// Used only on PHONE and TABLET-S tiers where sidebar is not persistent.
class _PhoneDrawerWrapper extends ConsumerWidget {
  const _PhoneDrawerWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-use the existing ConversationDrawer for phone mode
    return const _PhoneDrawer();
  }
}

/// The original Drawer-wrapped conversation list for phone layouts.
/// This is essentially the existing ConversationDrawer widget inlined.
class _PhoneDrawer extends ConsumerStatefulWidget {
  const _PhoneDrawer();

  @override
  ConsumerState<_PhoneDrawer> createState() => _PhoneDrawerState();
}

class _PhoneDrawerState extends ConsumerState<_PhoneDrawer> {
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

    return Drawer(
      child: SafeArea(
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
                Navigator.pop(context);
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
                    children: grouped.entries.expand((entry) {
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
                          return _DrawerConversationTile(
                            conversation: convo,
                            isActive: isActive,
                            colors: colors,
                            mono: mono,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(chatProvider.notifier).loadConversation(convo.id);
                              Navigator.pop(context);
                            },
                            onDelete: () => _confirmDelete(context, convo),
                            onRename: () => _showRename(context, convo),
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
              onTap: () {
                Navigator.pop(context);
                context.push('/models');
              },
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
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
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
}

class _DrawerConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final CyberTermColors colors;
  final TextStyle mono;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _DrawerConversationTile({
    required this.conversation,
    required this.isActive,
    required this.colors,
    required this.mono,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
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
              child: Column(
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
                  const SizedBox(height: 2),
                  Text(
                    '${conversation.modelName} · ${_formatDate(conversation.updatedAt)}',
                    style: mono.copyWith(color: colors.textDim, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
