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
import '../../data/models/ollama_error.dart';
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/conversation_drawer.dart';
import '../widgets/model_picker.dart';
import '../widgets/prompt_suggestions.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _showScrollToBottom = false;

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

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      drawer: const ConversationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Text('☰',
                style:
                    mono.copyWith(color: colors.primary, fontSize: 20)),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Conversations',
          ),
        ),
        title: Row(
          children: [
            Text(
              'ExecPrompt',
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
                          selectedModel,
                          style: mono.copyWith(
                              color: colors.textDim, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          size: 16, color: colors.textDim),
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
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Model warning
              if (selectedModel == null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: colors.error.withOpacity(0.3))),
                    color: colors.error.withOpacity(0.1),
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
                          style: mono.copyWith(
                              color: colors.error, fontSize: 12),
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
                        selectedModel: selectedModel,
                        onPromptTap: _fillPrompt,
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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

              // Error bar
              if (chatState.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: colors.error.withOpacity(0.3))),
                    color: colors.error.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Text('✕ ',
                          style: mono.copyWith(
                              color: colors.error, fontSize: 14)),
                      Expanded(
                        child: Text(
                          chatState.error!.userMessage,
                          style: mono.copyWith(
                              color: colors.error, fontSize: 11),
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
}
