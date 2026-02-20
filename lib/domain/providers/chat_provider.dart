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
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/chat_request.dart';
import '../../data/models/chat_response.dart';
import '../../data/models/chat_options.dart';
import '../../data/models/ollama_error.dart';
import '../../data/models/model_info.dart';
import '../../data/database/app_database.dart';
import '../../data/services/api_adapter.dart';
import '../models/tool_definition.dart';
import 'database_provider.dart';
import 'endpoint_provider.dart';
import 'settings_provider.dart';
import 'tool_provider.dart';

const _uuid = Uuid();

/// Conversation message with metadata
class ConversationMessage {
  final String id;
  final ChatMessage message;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isError;
  final List<String>? sourceUrls;

  ConversationMessage({
    String? id,
    required this.message,
    DateTime? timestamp,
    this.isStreaming = false,
    this.isError = false,
    this.sourceUrls,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  ConversationMessage copyWith({
    String? id,
    ChatMessage? message,
    DateTime? timestamp,
    bool? isStreaming,
    bool? isError,
    List<String>? sourceUrls,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      sourceUrls: sourceUrls ?? this.sourceUrls,
    );
  }
}

/// Chat state
class ChatState {
  final List<ConversationMessage> messages;
  final bool isLoading;
  final OllamaError? error;
  final String? currentStreamingContent;
  final String? currentStreamingThinking;
  final String? searchStatus;
  final int retryCount;
  final int totalInputTokens;
  final int totalOutputTokens;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.currentStreamingContent,
    this.currentStreamingThinking,
    this.searchStatus,
    this.retryCount = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
  });

  ChatState copyWith({
    List<ConversationMessage>? messages,
    bool? isLoading,
    OllamaError? error,
    String? currentStreamingContent,
    String? currentStreamingThinking,
    String? searchStatus,
    int? retryCount,
    bool clearSearchStatus = false,
    int? totalInputTokens,
    int? totalOutputTokens,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStreamingContent: currentStreamingContent,
      currentStreamingThinking: currentStreamingThinking,
      searchStatus: clearSearchStatus ? null : (searchStatus ?? this.searchStatus),
      retryCount: retryCount ?? this.retryCount,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
    );
  }
}

/// Chat notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  StreamSubscription<ChatResponse>? _currentStreamSubscription;
  int? _currentConversationId;
  ApiAdapter? _activeAdapter;

  ChatNotifier(this.ref) : super(ChatState());

  @override
  void dispose() {
    _currentStreamSubscription?.cancel();
    super.dispose();
  }

  AppDatabase get _db => ref.read(databaseProvider);

  /// Get current conversation ID
  int? get currentConversationId => _currentConversationId;

  /// Ensure a conversation exists in the database, creating one if needed
  Future<int> _ensureConversation(String firstMessage, String model) async {
    if (_currentConversationId != null) return _currentConversationId!;
    final title = firstMessage.length > 50
        ? '${firstMessage.substring(0, 50)}...'
        : firstMessage;
    final now = DateTime.now();
    final id = await _db.createConversation(ConversationsCompanion.insert(
      title: title,
      modelName: model,
      createdAt: now,
      updatedAt: now,
    ));
    _currentConversationId = id;
    ref.read(currentConversationIdProvider.notifier).state = id;
    return id;
  }

  /// Save a message to the database
  Future<void> _saveMessageToDb({
    required int conversationId,
    required String role,
    String? content,
    String? thinking,
    List<String>? images,
    String? toolCalls,
    String? toolName,
  }) async {
    await _db.addMessage(MessagesCompanion.insert(
      conversationId: conversationId,
      role: role,
      content: Value(content),
      thinking: Value(thinking),
      images: Value(images != null ? jsonEncode(images) : null),
      toolCalls: Value(toolCalls),
      toolName: Value(toolName),
      createdAt: DateTime.now(),
    ));
  }

  /// Load a conversation from the database
  Future<void> loadConversation(int conversationId) async {
    _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;

    try {
      final messages = await _db.getMessagesForConversation(conversationId);
      final conversationMessages = messages
          .where((m) => m.role != 'tool') // Don't show tool messages in UI
          .map((m) {
        List<String>? images;
        if (m.images != null) {
          try {
            images = (jsonDecode(m.images!) as List).cast<String>();
          } catch (_) {}
        }
        List<ToolCallWrapper>? toolCalls;
        if (m.toolCalls != null) {
          try {
            final decoded = jsonDecode(m.toolCalls!) as List;
            toolCalls = decoded.map((tc) {
              final fn = tc['function'] as Map<String, dynamic>;
              return ToolCallWrapper(
                function_: ToolCallFunction(
                  name: fn['name'] as String,
                  arguments: fn['arguments'] as Map<String, dynamic>,
                ),
              );
            }).toList();
          } catch (_) {}
        }
        return ConversationMessage(
          message: ChatMessage(
            role: m.role,
            content: m.content,
            thinking: m.thinking,
            images: images,
            toolCalls: toolCalls,
            toolName: m.toolName,
          ),
          timestamp: m.createdAt,
        );
      }).toList();

      _currentConversationId = conversationId;
      ref.read(currentConversationIdProvider.notifier).state = conversationId;
      state = ChatState(messages: conversationMessages);
    } catch (e) {
      state = state.copyWith(
        error: OllamaError.unknown(message: 'Failed to load conversation: $e'),
      );
    }
  }

  /// Start a new chat (clears state but doesn't delete from DB)
  void newChat() {
    _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;
    _currentConversationId = null;
    ref.read(currentConversationIdProvider.notifier).state = null;
    state = ChatState();
  }

  /// Delete a conversation from the database
  Future<void> deleteConversation(int conversationId) async {
    await _db.deleteConversation(conversationId);
    if (_currentConversationId == conversationId) {
      newChat();
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(int conversationId, String newTitle) async {
    final conversation = await _db.getConversation(conversationId);
    await _db.updateConversation(conversation.copyWith(title: newTitle));
  }

  void addUserMessage(String content, {List<String>? images}) {
    final userMessage = ConversationMessage(
      message: ChatMessage(
        role: 'user',
        content: content,
        images: images,
      ),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      error: null,
    );
  }

  Future<void> sendMessage(String content, {List<String>? images}) async {
    // Guard: cancel any in-flight request before starting a new one
    if (_currentStreamSubscription != null) {
      stopGeneration();
    }

    // Add user message to state
    addUserMessage(content, images: images);

    // Get selected model
    final selectedModel = ref.read(selectedModelProvider);
    if (selectedModel == null) {
      state = state.copyWith(
        error: const OllamaError.unknown(message: 'Please select a model first'),
        isLoading: false,
      );
      return;
    }

    // Resolve the adapter for this model's endpoint
    ApiAdapter adapter;
    final endpoint = ref.read(endpointForModelProvider(selectedModel));
    if (endpoint != null) {
      if (kDebugMode) debugPrint('🔌 Adapter: ${endpoint.type.name} (${endpoint.name}) → ${endpoint.baseUrl}');
      adapter = ref.read(adapterForEndpointProvider(endpoint));
    } else {
      // Fallback: try the legacy OllamaApiService path for backward compat
      if (kDebugMode) debugPrint('⚠️ No endpoint matched model "$selectedModel" — falling back to legacy adapter');
      final isConfigured = ref.read(isServerConfiguredProvider);
      if (!isConfigured) {
        state = state.copyWith(
          error: const OllamaError.unknown(
            message: 'No endpoint found for this model. Go to Settings to configure endpoints.',
          ),
          isLoading: false,
        );
        return;
      }
      // Use legacy adapter via ollamaApiServiceProvider
      final legacyService = ref.read(ollamaApiServiceProvider);
      final legacyUrl = ref.read(baseUrlProvider);
      if (kDebugMode) debugPrint('🔌 Adapter: _LegacyOllamaAdapter → $legacyUrl');
      adapter = _LegacyOllamaAdapter(legacyService);
    }
    _activeAdapter = adapter;

    // Ensure conversation exists in DB and save user message
    try {
      final convId = await _ensureConversation(content, selectedModel);
      await _saveMessageToDb(
        conversationId: convId,
        role: 'user',
        content: content,
        images: images,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to save to DB: $e');
    }

    // Start streaming
    state = state.copyWith(isLoading: true, error: null, clearSearchStatus: true);

    try {
      final chatOptions = ref.read(chatOptionsProvider);
      final systemPrompt = ref.read(systemPromptProvider);

      // Get active tools JSON if web search is enabled
      final toolsJson = ref.read(activeToolsJsonProvider);
      final toolRegistry = ref.read(toolRegistryProvider);

      // Build message history
      final messageHistory = state.messages
          .where((m) => !m.isError)
          .map((m) => m.message)
          .toList();

      // Add system prompt if provided
      final messages = systemPrompt != null && systemPrompt.isNotEmpty
          ? [ChatMessage(role: 'system', content: systemPrompt), ...messageHistory]
          : messageHistory;

      // When sendParameters is OFF, omit all optional parameters so the
      // model uses its own defaults. This avoids 400 errors from providers
      // that reject unsupported params (e.g. Gemini, gpt-5-mini).
      final sendParams = ref.read(sendParametersProvider);

      final request = ChatRequest(
        model: rawModelId(selectedModel),
        messages: messages,
        stream: true,
        options: sendParams ? chatOptions.toMap() : null,
        tools: toolsJson.isNotEmpty ? toolsJson : null,
      );

      if (kDebugMode) {
        debugPrint('🚀 Sending chat request to model: $selectedModel');
        debugPrint('📝 Message history length: ${messages.length}');
        debugPrint('🔧 Tools enabled: ${toolsJson.length}');
        debugPrint('🔌 Adapter: ${adapter.runtimeType}');
      }

      await _streamAndHandleToolCalls(
        adapter: adapter,
        request: request,
        selectedModel: selectedModel,
        chatOptions: chatOptions,
        systemPrompt: systemPrompt,
        toolRegistry: toolRegistry,
      );
    } catch (e) {
      state = state.copyWith(
        error: OllamaError.unknown(message: e.toString()),
        isLoading: false,
        currentStreamingContent: null,
        currentStreamingThinking: null,
        clearSearchStatus: true,
      );
    }
  }

  /// Core streaming method that handles tool call detection and re-send loop.
  /// Supports up to [_maxToolIterations] rounds of tool calls per message.
  static const _maxToolIterations = 5;

  /// Safety limit: abort streaming if content exceeds this length.
  /// Prevents runaway responses from overwhelming the UI / memory.
  static const _maxContentLength = 100000; // 100 KB

  /// Minimum interval between streaming UI state updates to prevent excessive
  /// widget rebuilds (especially for MarkdownBody re-parsing).
  static const _uiThrottleMs = 50;

  Future<void> _streamAndHandleToolCalls({
    required ApiAdapter adapter,
    required ChatRequest request,
    required String selectedModel,
    required dynamic chatOptions,
    required String? systemPrompt,
    required Map<String, ToolDefinition> toolRegistry,
    int iteration = 0,
    List<ChatMessage>? accumulatedToolMessages,
  }) async {
    final toolMessages = accumulatedToolMessages ?? <ChatMessage>[];
    String accumulatedContent = '';
    String accumulatedThinking = '';
    List<ToolCallWrapper>? detectedToolCalls;
    final assistantId = _uuid.v4();
    bool doneHandled = false;
    int lastUiUpdateMs = 0;
    int? responseInputTokens;
    int? responseOutputTokens;

    final completer = Completer<void>();

    final stream = adapter.streamChat(request);
    _currentStreamSubscription = stream.listen(
      (ChatResponse response) async {
        if (!mounted) return;

        // Guard: if done was already handled, ignore further events
        if (doneHandled && !response.done) return;

        // Accumulate content
        if (response.message?.content != null && response.message!.content!.isNotEmpty) {
          accumulatedContent += response.message!.content!;
        }

        // Accumulate thinking
        if (response.message?.thinking != null && response.message!.thinking!.isNotEmpty) {
          accumulatedThinking += response.message!.thinking!;
        }

        // Detect tool calls
        if (response.message?.toolCalls != null && response.message!.toolCalls!.isNotEmpty) {
          detectedToolCalls ??= [];
          detectedToolCalls!.addAll(response.message!.toolCalls!);
        }

        // Safety: abort if content exceeds max length
        if (accumulatedContent.length > _maxContentLength) {
          if (kDebugMode) debugPrint('⚠️ Content exceeded $_maxContentLength chars – aborting stream');
          try {
            adapter.cancelActiveRequest();
          } catch (_) {}
          _currentStreamSubscription?.cancel();
          // Fall through to done handling below
          response = ChatResponse(
            model: response.model,
            createdAt: response.createdAt,
            done: true,
            doneReason: 'length',
            message: const ChatMessage(role: 'assistant'),
          );
        }

        // Throttle UI updates to prevent excessive rebuilds.
        // Always update on done, and on the first chunk.
        if (!response.done) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastUiUpdateMs >= _uiThrottleMs) {
            lastUiUpdateMs = now;
            state = state.copyWith(
              currentStreamingContent: accumulatedContent.isNotEmpty ? accumulatedContent : null,
              currentStreamingThinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
            );
          }
          return;
        }

        // ── Done handling ──
        if (doneHandled) return; // guard against duplicate done events
        doneHandled = true;

        // Capture token usage from the final response
        responseInputTokens = response.promptEvalCount ?? responseInputTokens;
        responseOutputTokens = response.evalCount ?? responseOutputTokens;

        // Final UI update with complete content
        state = state.copyWith(
          currentStreamingContent: accumulatedContent.isNotEmpty ? accumulatedContent : null,
          currentStreamingThinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
        );

        if (kDebugMode) debugPrint('✅ Stream completed. Content: ${accumulatedContent.length} chars, Thinking: ${accumulatedThinking.length} chars, ToolCalls: ${detectedToolCalls?.length ?? 0}');

          // ── Tool call detected → execute and re-send ──
          if (detectedToolCalls != null && detectedToolCalls!.isNotEmpty && iteration < _maxToolIterations) {
            // Add the assistant's tool-call message to history
            final assistantToolMsg = ChatMessage(
              role: 'assistant',
              content: accumulatedContent.isNotEmpty ? accumulatedContent : null,
              thinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
              toolCalls: detectedToolCalls,
            );
            toolMessages.add(assistantToolMsg);

            // Execute each tool call
            for (final toolCall in detectedToolCalls!) {
              final toolName = toolCall.function_.name;
              final toolArgs = toolCall.function_.arguments;

              state = state.copyWith(
                searchStatus: 'Searching the web...',
              );

              final tool = toolRegistry[toolName];
              String result;
              if (tool != null) {
                try {
                  result = await tool.execute(toolArgs);
                  if (kDebugMode) debugPrint('🔧 Tool "$toolName" returned ${result.length} chars');
                } catch (e) {
                  result = '{"error": "Tool execution failed: $e"}';
                  if (kDebugMode) debugPrint('❌ Tool "$toolName" failed: $e');
                }
              } else {
                result = '{"error": "Unknown tool: $toolName"}';
                if (kDebugMode) debugPrint('⚠️ Unknown tool: $toolName');
              }

              // Add tool result message (format varies by adapter)
              toolMessages.add(adapter.buildToolResultMessage(
                toolName: toolName,
                content: result,
                toolCallId: toolCall.id,
              ));
            }

            state = state.copyWith(
              searchStatus: 'Processing results...',
              currentStreamingContent: null,
              currentStreamingThinking: null,
            );

            // Build updated message history with tool messages
            final baseMessages = request.messages ?? [];
            final updatedMessages = [...baseMessages, ...toolMessages];

            final nextRequest = request.copyWith(
              messages: updatedMessages,
              // Don't send tools on re-send to avoid loops
              tools: null,
            );

            _currentStreamSubscription = null;

            // Recurse for the model's final response
            await _streamAndHandleToolCalls(
              adapter: adapter,
              request: nextRequest,
              selectedModel: selectedModel,
              chatOptions: chatOptions,
              systemPrompt: systemPrompt,
              toolRegistry: toolRegistry,
              iteration: iteration + 1,
              accumulatedToolMessages: toolMessages,
            );

            if (!completer.isCompleted) completer.complete();
            return;
          }

          // ── Normal completion (no tool calls or max iterations reached) ──

          // Extract source URLs from tool results for citation rendering
          List<String>? sourceUrls;
          if (toolMessages.isNotEmpty) {
            sourceUrls = _extractSourceUrls(toolMessages);
          }

          final assistantMessage = ConversationMessage(
            id: assistantId,
            message: ChatMessage(
              role: 'assistant',
              content: accumulatedContent.isNotEmpty ? accumulatedContent : null,
              thinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
            ),
            sourceUrls: sourceUrls,
          );

          state = state.copyWith(
            messages: [...state.messages, assistantMessage],
            isLoading: false,
            currentStreamingContent: null,
            currentStreamingThinking: null,
            clearSearchStatus: true,
            totalInputTokens: state.totalInputTokens + (responseInputTokens ?? 0),
            totalOutputTokens: state.totalOutputTokens + (responseOutputTokens ?? 0),
          );

          // Save to DB
          if (_currentConversationId != null) {
            try {
              // Save any tool messages that were part of this exchange
              for (final toolMsg in toolMessages) {
                await _saveMessageToDb(
                  conversationId: _currentConversationId!,
                  role: toolMsg.role,
                  content: toolMsg.content,
                  thinking: toolMsg.thinking,
                  toolCalls: toolMsg.toolCalls != null
                      ? jsonEncode(toolMsg.toolCalls!.map((tc) => {
                            'function': {
                              'name': tc.function_.name,
                              'arguments': tc.function_.arguments,
                            }
                          }).toList())
                      : null,
                  toolName: toolMsg.toolName,
                );
              }
              // Save the final assistant message
              await _saveMessageToDb(
                conversationId: _currentConversationId!,
                role: 'assistant',
                content: accumulatedContent.isNotEmpty ? accumulatedContent : null,
                thinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
              );
            } catch (e) {
              if (kDebugMode) debugPrint('⚠️ Failed to save assistant message to DB: $e');
            }
          }

          _currentStreamSubscription = null;
          if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        if (!mounted) return;
        if (kDebugMode) debugPrint('❌ Stream error: $e');
        state = state.copyWith(
          error: OllamaError.unknown(message: e.toString()),
          isLoading: false,
          currentStreamingContent: null,
          currentStreamingThinking: null,
          clearSearchStatus: true,
        );
        _currentStreamSubscription = null;
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!mounted) return;
        if (state.isLoading && _currentStreamSubscription != null) {
          // Stream ended unexpectedly
          if (accumulatedContent.isNotEmpty || accumulatedThinking.isNotEmpty) {
            final assistantMessage = ConversationMessage(
              id: assistantId,
              message: ChatMessage(
                role: 'assistant',
                content: accumulatedContent.isNotEmpty ? accumulatedContent : null,
                thinking: accumulatedThinking.isNotEmpty ? accumulatedThinking : null,
              ),
            );
            state = state.copyWith(
              messages: [...state.messages, assistantMessage],
              isLoading: false,
              currentStreamingContent: null,
              currentStreamingThinking: null,
              clearSearchStatus: true,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              currentStreamingContent: null,
              currentStreamingThinking: null,
              clearSearchStatus: true,
            );
          }
        }
        _currentStreamSubscription = null;
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Stop the current generation
  void stopGeneration() {
    // 1. Cancel the HTTP request at the wire level via the active adapter
    try {
      _activeAdapter?.cancelActiveRequest();
    } catch (_) {
      // Fallback: try legacy path
      try {
        final apiService = ref.read(ollamaApiServiceProvider);
        apiService.cancelActiveRequest();
      } catch (_) {}
    }

    // 2. Cancel the stream subscription
    _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;

    // 3. Finalize state directly — don't rely on onDone
    if (state.isLoading) {
      final content = state.currentStreamingContent;
      final thinking = state.currentStreamingThinking;

      if (content != null && content.isNotEmpty || thinking != null && thinking.isNotEmpty) {
        // Save partial content as a message
        final assistantMessage = ConversationMessage(
          message: ChatMessage(
            role: 'assistant',
            content: content,
            thinking: thinking,
          ),
        );

        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isLoading: false,
          currentStreamingContent: null,
          currentStreamingThinking: null,
        );

        // Persist partial message to DB
        if (_currentConversationId != null) {
          _saveMessageToDb(
            conversationId: _currentConversationId!,
            role: 'assistant',
            content: content,
            thinking: thinking,
          ).catchError((e) { if (kDebugMode) debugPrint('⚠️ Failed to save partial message: $e'); });
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          currentStreamingContent: null,
          currentStreamingThinking: null,
        );
      }

      if (kDebugMode) debugPrint('🛑 Generation stopped by user');
    }
  }

  /// Retry the last failed message
  Future<void> retryLastMessage() async {
    // Find the last user message
    ConversationMessage? lastUserMessage;
    int lastUserIndex = -1;
    for (int i = state.messages.length - 1; i >= 0; i--) {
      if (state.messages[i].message.role == 'user') {
        lastUserMessage = state.messages[i];
        lastUserIndex = i;
        break;
      }
    }

    if (lastUserMessage == null) return;

    // Remove the last user message and any assistant response after it
    final messagesUpTo = state.messages.sublist(0, lastUserIndex);
    state = state.copyWith(messages: messagesUpTo, error: null);

    // Resend
    await sendMessage(
      lastUserMessage.message.content ?? '',
      images: lastUserMessage.message.images,
    );
  }

  void clearChat() {
    _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;
    state = ChatState();
  }

  void removeMessage(String messageId) {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != messageId).toList(),
    );
  }

  /// Edit a user message: removes it and all subsequent messages,
  /// returns the original message content for editing.
  String? editMessageAt(String messageId) {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return null;

    final message = state.messages[index];
    final content = message.message.content;

    // Remove this message and everything after it
    final kept = state.messages.sublist(0, index);
    state = state.copyWith(messages: kept, error: null);

    return content;
  }

  /// Fork the conversation at a specific message.
  ///
  /// Creates a new conversation containing all messages up to and including
  /// the message with [messageId]. The new conversation is loaded as the
  /// current active conversation so the user can continue from that point.
  Future<void> forkConversation(String messageId) async {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    // Get the forked subset of messages (inclusive of messageId)
    final forkedMessages = state.messages.sublist(0, index + 1);
    if (forkedMessages.isEmpty) return;

    // Determine title from the first user message
    final firstUserContent = forkedMessages
        .where((m) => m.message.role == 'user' && m.message.content != null)
        .map((m) => m.message.content!)
        .firstOrNull ?? 'Forked conversation';
    final title = firstUserContent.length > 50
        ? '${firstUserContent.substring(0, 50)}...'
        : firstUserContent;

    // Get the current model
    final selectedModel = ref.read(selectedModelProvider);
    final model = selectedModel ?? 'unknown';

    // Create new conversation in DB
    final now = DateTime.now();
    final newConvId = await _db.createConversation(ConversationsCompanion.insert(
      title: '⑂ $title',
      modelName: model,
      createdAt: now,
      updatedAt: now,
    ));

    // Save each message to the new conversation
    for (final msg in forkedMessages) {
      String? toolCalls;
      if (msg.message.toolCalls != null) {
        toolCalls = jsonEncode(msg.message.toolCalls!.map((tc) => {
          'function': {
            'name': tc.function_.name,
            'arguments': tc.function_.arguments,
          },
        }).toList());
      }
      await _saveMessageToDb(
        conversationId: newConvId,
        role: msg.message.role,
        content: msg.message.content,
        thinking: msg.message.thinking,
        images: msg.message.images,
        toolCalls: toolCalls,
        toolName: msg.message.toolName,
      );
    }

    // Switch to the forked conversation
    await loadConversation(newConvId);
    if (kDebugMode) debugPrint('🔀 Forked conversation at message $messageId → new conv #$newConvId');
  }

  /// Extract unique source URLs from tool result messages.
  List<String>? _extractSourceUrls(List<ChatMessage> toolMessages) {
    final urls = <String>{};
    for (final msg in toolMessages) {
      if (msg.role == 'tool' && msg.content != null) {
        try {
          final decoded = jsonDecode(msg.content!);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic> && item['url'] != null) {
                final url = item['url'] as String;
                if (url.isNotEmpty) urls.add(url);
              }
            }
          }
        } catch (_) {
          // Not valid JSON — skip
        }
      }
    }
    return urls.isNotEmpty ? urls.toList() : null;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

// ---------------------------------------------------------------------------
// Legacy backward-compat adapter
// ---------------------------------------------------------------------------

/// Thin wrapper so the legacy [OllamaApiService] can be used as an
/// [ApiAdapter] during the migration period. This allows users who haven't
/// configured endpoints yet to keep chatting via the old settings.
class _LegacyOllamaAdapter extends ApiAdapter {
  final dynamic _service;
  _LegacyOllamaAdapter(this._service);

  @override
  Stream<ChatResponse> streamChat(ChatRequest request) => _service.streamChat(request);
  @override
  Future<List<ModelInfo>> listModels() async => [];
  @override
  void cancelActiveRequest() => _service.cancelActiveRequest();
  @override
  ChatMessage buildToolResultMessage({
    required String toolName,
    required String content,
    String? toolCallId,
  }) =>
      ChatMessage(role: 'tool', content: content, toolName: toolName);
  @override
  void updateBaseUrl(String url) => _service.updateBaseUrl(url);
  @override
  void updateApiKey(String? key) => _service.updateApiKey(key);
  @override
  Future<String> testConnection() async => 'Legacy';
}
