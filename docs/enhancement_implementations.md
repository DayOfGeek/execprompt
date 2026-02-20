# Enhancement Implementation Plan

**Generated:** 2026-02-11  
**Based on:** enhancements.md + full codebase audit  
**Strategy:** Wire database → Build drawer → Apply theme → Polish UX

---

## Code Audit: Issues Found Before Implementation

### Critical Issues
1. **Database exists but is completely disconnected** — `AppDatabase` and `database_provider.dart` exist but `ChatNotifier` never writes to or reads from the database. All chat is ephemeral.
2. **No conversation lifecycle** — No concept of "current conversation". Every app restart loses all history.
3. **ChatNotifier.copyWith has a bug** — The `error` field in `copyWith` always replaces with the parameter value (including null), meaning you can never "keep" the existing error via copyWith. This is actually intentional but could confuse.

### Functional Gaps
4. **No way to start a new chat** — Only one conversation exists at a time, cleared via "Clear Chat" which destroys everything.
5. **Model selector requires leaving chat** — Must navigate to Models screen, losing mental context.
6. **Settings screen wastes space** — Large cards with lots of padding, Quick Links section has low value, About section is sparse.
7. **No data export/import** — Can't back up conversations.
8. **No theme system** — Hardcoded `deepPurple` seed color with system light/dark only.
9. **Code blocks have no syntax highlighting** — `flutter_markdown` renders code but all one color.
10. **No haptic feedback** — Touch interactions feel flat.

### UX Gaps
11. **Empty state is generic** — "Start a conversation" with no prompt suggestions.
12. **No scroll-to-bottom button** — When scrolled up reading history, no easy way to jump to latest.
13. **No conversation title visible** — No way to know which conversation you're in.
14. **Streaming uses spinner** — Circular progress indicator instead of immersive cursor.

---

## Implementation Plan

### Phase 1: Conversation Management + Database Wiring

**Goal:** Make the app actually save and manage conversations

#### 1.1 Update ChatNotifier to use database

**File:** `lib/domain/providers/chat_provider.dart`

Changes needed:
- Add `AppDatabase` dependency via ref
- Add `currentConversationId` state field
- On `sendMessage()`: If no current conversation, create one in DB with title from first message
- After each message (user + assistant): Write to Messages table
- On `clearChat()`: Just reset state, don't delete from DB
- Add `loadConversation(int id)` method to restore from DB
- Add `newChat()` method to start fresh

```dart
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  int? _currentConversationId;
  
  // On first user message:
  Future<int> _ensureConversation(String firstMessage, String model) async {
    if (_currentConversationId != null) return _currentConversationId!;
    final db = ref.read(databaseProvider);
    final title = firstMessage.length > 40 
        ? '${firstMessage.substring(0, 40)}...' 
        : firstMessage;
    final id = await db.createConversation(ConversationsCompanion.insert(
      title: title,
      modelName: model,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    _currentConversationId = id;
    ref.read(currentConversationIdProvider.notifier).state = id;
    return id;
  }
  
  Future<void> loadConversation(int conversationId) async {
    final db = ref.read(databaseProvider);
    final messages = await db.getMessagesForConversation(conversationId);
    // Convert DB messages to ConversationMessage list
    // Set state with loaded messages
    _currentConversationId = conversationId;
  }
  
  void newChat() {
    _currentStreamSubscription?.cancel();
    _currentConversationId = null;
    ref.read(currentConversationIdProvider.notifier).state = null;
    state = ChatState();
  }
}
```

#### 1.2 Update database_provider.dart

**File:** `lib/domain/providers/database_provider.dart`

Changes needed:
- Fix `conversationsProvider` to use proper stream query (currently broken — `select().watch()` doesn't include ordering)
- Add `searchConversationsProvider` for search functionality
- Add conversation action methods (rename, delete, archive)

```dart
// Proper ordered stream
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.conversations)
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
    .watch();
});

// Search
final conversationSearchQueryProvider = StateProvider<String>((ref) => '');
final filteredConversationsProvider = Provider<AsyncValue<List<Conversation>>>((ref) {
  final query = ref.watch(conversationSearchQueryProvider).toLowerCase();
  final conversations = ref.watch(conversationsProvider);
  if (query.isEmpty) return conversations;
  return conversations.whenData((list) => 
    list.where((c) => c.title.toLowerCase().contains(query)).toList()
  );
});
```

#### 1.3 Create Conversation Drawer Widget

**New file:** `lib/presentation/widgets/conversation_drawer.dart`

A `Drawer` widget that shows:
- "New Chat" button at top
- Search bar
- Grouped conversation list (Today / Yesterday / Previous 7 Days / Older)
- Each item shows: title (truncated), model name, relative timestamp
- Swipe-to-delete or long-press menu (rename, delete)
- Settings and Models links at bottom

```dart
class ConversationDrawer extends ConsumerWidget {
  // Groups conversations by date
  // Today, Yesterday, Previous 7 Days, This Month, Older
  
  Map<String, List<Conversation>> _groupByDate(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    
    // Group into buckets
  }
}
```

#### 1.4 Update ChatScreen for Drawer + New Chat

**File:** `lib/presentation/screens/chat_screen.dart`

Changes needed:
- Add `Scaffold.drawer` with ConversationDrawer
- Replace hamburger/menu icon in AppBar leading
- Add "New Chat" FAB or button
- Show conversation title in AppBar
- Remove separate Models/Settings nav (move to drawer bottom)

#### 1.5 Update main.dart routing

**File:** `lib/main.dart`

Changes needed:
- Keep `/chat` as main route
- Add `/chat/:conversationId` route for loading specific conversations
- Keep models and settings as push routes

---

### Phase 2: Retro Theme System

**Goal:** Transform the app from generic Material to unique CyberTerm aesthetic

#### 2.1 Create Theme Data

**New file:** `lib/presentation/theme/cyberterm_theme.dart`

Contains:
- `CyberTermTheme` enum: `p1Green`, `p3Amber`, `p4White`, `neonCyan`, `synthwave`
- `CyberTermColors` class with all color properties
- `buildThemeData(CyberTermTheme theme)` that returns a full `ThemeData`
- Monospace font configuration (google_fonts package for JetBrains Mono)

```dart
enum CyberTermTheme {
  p1Green('P1 Green', 'Classic terminal phosphor'),
  p3Amber('P3 Amber', 'Warm amber glow'),
  p4White('P4 White', 'Cool bright terminal'),
  neonCyan('Neon Cyan', 'Cyberpunk edge'),
  synthwave('Synthwave', '80s retro vibes');
  
  final String displayName;
  final String description;
  const CyberTermTheme(this.displayName, this.description);
}

class CyberTermColors {
  final Color background;
  final Color surface;
  final Color primary;
  final Color primaryDim;
  final Color textColor;
  final Color textDim;
  final Color accent;
  final Color error;
  final Color border;
  final Color userBubble;
  final Color botBubble;
  // ...
}
```

#### 2.2 Add Theme Provider

**File:** `lib/domain/providers/settings_provider.dart`

Changes needed:
- Add `themeProvider` that reads/writes theme selection to SharedPreferences
- Add `saveTheme()` function

#### 2.3 Add Google Fonts dependency

**File:** `pubspec.yaml`

Add `google_fonts: ^6.1.0` for JetBrains Mono monospace font.

#### 2.4 Update main.dart to use theme

**File:** `lib/main.dart`

Changes needed:
- Replace hardcoded `ThemeData` with `buildThemeData(currentTheme)`
- Watch theme provider
- Always use dark base since all themes are dark-background

#### 2.5 Create Theme Selector Widget

**New file:** `lib/presentation/widgets/theme_selector.dart`

A visual grid showing each theme as a small preview card with its colors. Tap to select.

---

### Phase 3: UI Overhaul — Terminal Aesthetic

**Goal:** Apply the retro design language to all widgets

#### 3.1 Redesign MessageBubble

**File:** `lib/presentation/widgets/message_bubble.dart`

Changes from current:
- Remove `CircleAvatar` role indicators → Use text tags `[USR]` / `[BOT]` 
- Remove rounded `BorderRadius.circular(16)` → Sharp corners or 2px radius max
- Add 1px border in theme primary color (dim)
- Use monospace font for all text
- Timestamp format: `[HH:mm:ss]` in dim color
- Streaming indicator: blinking `█` character instead of `CircularProgressIndicator`
- Thinking section: `[THINKING...]` header with monospace text
- Code blocks: bordered container with header showing language

#### 3.2 Redesign ChatInput

**File:** `lib/presentation/widgets/chat_input.dart`

Changes from current:
- Remove `FloatingActionButton` → Simple bordered button with `↵` or `>` 
- Remove rounded `BorderRadius.circular(24)` → Sharp rectangular input
- Add terminal prompt indicator `> ` before input
- Remove shadow → Use 1px top border
- Stop button: `[STOP]` text instead of red circle

#### 3.3 Redesign AppBar

All screens need terminal-style headers:
- Dark background matching theme
- Monospace font
- Status indicators (connection dot, model name)
- No elevation/shadow → Bottom border line

#### 3.4 Redesign Settings Screen

**File:** `lib/presentation/screens/settings_screen.dart`

Current problems:
- Cards with `Padding(16)` all around waste space
- "Quick Links" section is low-value filler
- "About" section is sparse
- Server Status is buried

Redesign:
- Remove card wrappers → Use section headers with `───` dividers
- Consolidate into sections: Connection, Model Config, Appearance, Data, About
- Add theme selector to Appearance section
- Add data management: Export conversations (JSON), Import, Clear all data
- Move Quick Links into an expandable section
- Add app diagnostics: DB size, conversation count, message count

#### 3.5 Empty State Redesign

Replace generic "Start a conversation" with retro terminal boot sequence:

```
> EXECPROMPT v1.0 [READY]
> CONNECTED TO: ollama.example.com
> MODEL LOADED: qwen3:8b
> 
> SUGGESTED PROMPTS:
>   [1] Explain quantum computing simply
>   [2] Write a Python sorting algorithm
>   [3] Summarize the latest tech news
>   [4] Help me debug my code
>
> TYPE A MESSAGE TO BEGIN_
```

Each suggestion is tappable and fills the input.

#### 3.6 Streaming Cursor

Replace `CircularProgressIndicator` with a blinking block cursor `█` widget:

```dart
class BlinkingCursor extends StatefulWidget {
  // AnimationController with 530ms period
  // Toggles opacity 1.0 ↔ 0.3
  // Uses theme primary color
}
```

---

### Phase 4: Chat Experience Polish

#### 4.1 Model Selector in Chat Header

Add a dropdown/bottom sheet in the chat AppBar that lets you switch models without leaving the chat screen.

```dart
// In AppBar, wrap model name in InkWell
InkWell(
  onTap: () => _showModelPicker(context),
  child: Row(
    children: [
      Text(selectedModel ?? 'No model', style: monoStyle),
      Icon(Icons.arrow_drop_down, color: theme.primaryDim),
    ],
  ),
)
```

Bottom sheet shows available models as a simple list — tap to switch.

#### 4.2 Code Block Enhancements

Add `flutter_highlight` package for syntax highlighting in code blocks.

Custom `MarkdownBody` builder that intercepts code blocks:
- Adds a header bar with language name + copy button
- Applies syntax highlighting theme matching our phosphor colors
- Wraps in bordered container

#### 4.3 Edit & Resend User Messages

Long-press on user message → "Edit" option.
Opens message text in input field, removes original + all subsequent messages, user can edit and resend.

#### 4.4 Scroll-to-Bottom FAB

When user scrolls up more than ~200px from bottom, show a small floating button to jump back to latest message.

```dart
// In ChatScreen, listen to scroll position
_scrollController.addListener(() {
  final isNearBottom = _scrollController.position.maxScrollExtent - 
    _scrollController.position.pixels < 200;
  setState(() => _showScrollButton = !isNearBottom);
});
```

#### 4.5 Haptic Feedback

Add `HapticFeedback.lightImpact()` on:
- Send message
- Select model
- Theme change
- Delete conversation
- Copy to clipboard

---

### Phase 5: Settings Cleanup & Data Management

#### 5.1 New Settings Layout

```
┌──────────────────────────────────────┐
│ ▸ SETTINGS                           │
│ ─────────────────────────────────── │
│                                      │
│ CONNECTION                           │
│   Server URL: https://ollama.com     │
│   API Key: ••••••••                  │
│   Status: ● Connected (v0.5.7)      │
│   [Test Connection]                  │
│                                      │
│ ─────────────────────────────────── │
│ MODEL PARAMETERS                     │
│   Temperature: 0.70 ──────●──       │
│   Top-K: 40         ────●────       │
│   Top-P: 0.90       ────────●─      │
│   Repeat Penalty: 1.10  ──●──      │
│   System Prompt: [Edit...]           │
│   [Advanced...] [Reset Defaults]     │
│                                      │
│ ─────────────────────────────────── │
│ APPEARANCE                           │
│   Theme: [P1 Green ▼]               │
│   Preview: ██████████████            │
│                                      │
│ ─────────────────────────────────── │
│ DATA MANAGEMENT                      │
│   Conversations: 42 (156 messages)   │
│   Database size: 2.4 MB              │
│   [Export All] [Import] [Clear All]  │
│                                      │
│ ─────────────────────────────────── │
│ ABOUT                                │
│   ExecPrompt v1.0.0                    │
│   Built with Flutter 3.38.9         │
│   [GitHub] [Report Issue]            │
└──────────────────────────────────────┘
```

#### 5.2 Useful Settings Functions to Add
- **Export conversations** — JSON file containing all conversations + messages
- **Import conversations** — Load from JSON backup
- **Clear all data** — Delete all conversations + messages with confirmation
- **Database statistics** — Count conversations, messages, DB file size
- **Connection diagnostics** — Test URL, measure latency, check version
- **Reset all settings** — Restore all preferences to factory defaults

---

## Dependency Changes

### New packages needed:
```yaml
dependencies:
  google_fonts: ^6.1.0       # JetBrains Mono monospace font
  flutter_highlight: ^0.7.0  # Syntax highlighting for code blocks
  share_plus: ^7.2.1         # Share conversations (export)
```

### Existing packages (no changes):
- drift (already have, need to wire up)
- shared_preferences (already have, need theme preference)
- flutter_markdown (already have, need custom builders)

---

## File Change Summary

### New Files (7)
| File | Purpose |
|------|---------|
| `lib/presentation/theme/cyberterm_theme.dart` | Theme definitions, colors, ThemeData builder |
| `lib/presentation/widgets/conversation_drawer.dart` | Conversation history sidebar |
| `lib/presentation/widgets/theme_selector.dart` | Visual theme picker for settings |
| `lib/presentation/widgets/blinking_cursor.dart` | Terminal-style streaming cursor |
| `lib/presentation/widgets/prompt_suggestions.dart` | Retro empty state with tappable prompts |
| `lib/presentation/widgets/model_picker.dart` | Bottom sheet model selector for chat |
| `lib/presentation/widgets/code_block_builder.dart` | Syntax-highlighted code block widget |

### Modified Files (9)
| File | Changes |
|------|---------|
| `lib/main.dart` | Theme system, routing updates |
| `lib/domain/providers/chat_provider.dart` | Database wiring, conversation lifecycle |
| `lib/domain/providers/database_provider.dart` | Fix providers, add search/actions |
| `lib/domain/providers/settings_provider.dart` | Theme provider, data management |
| `lib/presentation/screens/chat_screen.dart` | Drawer, model picker, scroll FAB, new chat |
| `lib/presentation/screens/settings_screen.dart` | Complete redesign with new sections |
| `lib/presentation/screens/models_screen.dart` | Terminal styling |
| `lib/presentation/widgets/message_bubble.dart` | Terminal-style redesign |
| `lib/presentation/widgets/chat_input.dart` | Terminal prompt style |
| `pubspec.yaml` | New dependencies |

### Database Schema (no changes needed)
The existing Drift schema in `app_database.dart` is sufficient:
- `Conversations` table: id, title, modelName, createdAt, updatedAt ✅
- `Messages` table: id, conversationId, role, content, thinking, images, createdAt ✅

---

## Implementation Sequence

Execute in this exact order to maintain a working app at each step:

```
Phase 1.1  → Wire database to chat provider (core plumbing)
Phase 1.2  → Fix database providers
Phase 1.3  → Build conversation drawer
Phase 1.4  → Update chat screen for drawer + new chat
Phase 2.1  → Create theme data (all 5 palettes)
Phase 2.2  → Theme provider + persistence
Phase 2.3  → Add google_fonts dependency
Phase 2.4  → Apply theme to main.dart
Phase 3.1  → Redesign message bubble
Phase 3.2  → Redesign chat input
Phase 3.3  → Terminal-style app bars
Phase 3.4  → Redesign settings screen
Phase 3.5  → Empty state with prompt suggestions
Phase 3.6  → Blinking cursor widget
Phase 4.1  → Model selector in chat
Phase 4.2  → Code block enhancements
Phase 4.3  → Edit & resend messages
Phase 4.4  → Scroll-to-bottom FAB
Phase 4.5  → Haptic feedback
Phase 5.1  → Settings cleanup
Phase 5.2  → Data management functions
```

Total new/modified files: 16  
Estimated total effort: ~29 hours  
Can be done incrementally — app works after each phase
