# Gap Remediation Plan

**Generated:** 2026-02-11  
**Based on:** ollama_gap_analysis.md  
**Priority Focus:** Critical bugs first, then high-value features

---

## Part 1: Critical Fixes (DO IMMEDIATELY)

### 🔴 CRITICAL-1: Fix Thinking Content Parsing
**Problem:** Thinking models completely broken - type cast error  
**Root Cause:** `ChatMessage.content` is `required String` but should be nullable  
**Impact:** App crashes when using thinking models (kimi-k2.5, deepseek, etc.)

**Technical Analysis:**
```dart
// Current (BROKEN):
class ChatMessage {
  required String content;   // ❌ Fails when content = ""
  String? thinking;
}

// Problem JSON:
{"message":{"role":"assistant","content":"","thinking":" The"},"done":false}

// Error:
type 'Null' is not a subtype of type 'String' in type cast
```

**Root Issue:**
- Freezed/json_serializable may be treating empty string as null in some contexts
- When `thinking` is present, `content` is often empty string
- Parser fails to deserialize the message

**Solution:**
1. Make `content` nullable in ChatMessage model
2. Add default value handling: `content ?? ''`
3. Update all usages to handle null content
4. Add thinking accumulation logic (separate from content)
5. Build thinking display UI component

**Files to Change:**
- `lib/data/models/chat_message.dart` - Make content nullable
- `lib/domain/providers/chat_provider.dart` - Accumulate thinking separately
- `lib/domain/providers/chat_state.dart` - Add currentStreamingThinking field
- `lib/presentation/widgets/message_bubble.dart` - Display thinking
- `lib/presentation/widgets/thinking_section.dart` - NEW file

**Implementation Steps:**
1. Update ChatMessage model:
```dart
class ChatMessage {
  required String role;
  String? content;           // ✅ Make nullable
  String? thinking;          // ✅ Already nullable
  List<String>? images;
  List<ToolCall>? toolCalls;
}
```

2. Update chat provider accumulation:
```dart
// Accumulate both content AND thinking
String accumulatedContent = '';
String accumulatedThinking = '';

stream.listen((response) {
  if (response.message?.content != null && response.message!.content!.isNotEmpty) {
    accumulatedContent += response.message!.content!;
  }
  if (response.message?.thinking != null && response.message!.thinking!.isNotEmpty) {
    accumulatedThinking += response.message!.thinking!;
  }
  
  state = state.copyWith(
    currentStreamingContent: accumulatedContent,
    currentStreamingThinking: accumulatedThinking, // NEW
  );
});
```

3. Create ThinkingSection widget:
```dart
class ThinkingSection extends StatefulWidget {
  final String thinking;
  final bool isStreaming;
  
  // Collapsible with AnimatedContainer
  // Monospace font for thinking
  // "💭 Thinking..." header
}
```

4. Update MessageBubble to include thinking:
```dart
Column(
  children: [
    if (message.thinking != null && message.thinking!.isNotEmpty)
      ThinkingSection(thinking: message.thinking!),
    MarkdownBody(data: message.content ?? ''),
  ],
)
```

**Testing:**
- Use kimi-k2.5 model
- Verify thinking displays in collapsed section
- Verify content displays below thinking
- Verify expand/collapse works
- Test with non-thinking models (should not show section)

**Dependencies:** NONE - can implement immediately  
**Time Estimate:** 2-3 hours  
**Priority:** P0 - BLOCKING

---

## Part 2: High-Value Quick Wins (NEXT SPRINT)

### 🟠 HIGH-2: Model Configuration (Temperature, etc.)
**Problem:** No way to control model behavior  
**Value:** Huge UX improvement, essential feature

**Solution:**
1. Create ChatOptions model:
```dart
@freezed
class ChatOptions {
  const factory ChatOptions({
    @Default(0.7) double temperature,
    @Default(40) int topK,
    @Default(0.9) double topP,
    int? numPredict,
    @Default(1.1) double repeatPenalty,
    int? seed,
  }) = _ChatOptions;
}
```

2. Add to settings screen:
- Temperature slider (0.0 - 2.0)
- Top-K slider (1 - 100)
- Top-P slider (0.0 - 1.0)
- Max tokens input
- System prompt text field

3. Store in Riverpod providers
4. Pass in ChatRequest options field

**Dependencies:** None  
**Time Estimate:** 3-4 hours  
**Priority:** P1

---

### 🟠 HIGH-3: Conversation Persistence
**Problem:** All conversations lost on app restart  
**Value:** Essential for real-world usage

**Solution:**
1. Add drift package for SQLite:
```yaml
dependencies:
  drift: ^2.20.0
  drift_flutter: ^0.2.0
```

2. Create schema:
```dart
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(Conversations, #id)();
  TextColumn get role => text()();
  TextColumn get content => text().nullable()();
  TextColumn get thinking => text().nullable()();
  TextColumn get images => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
}
```

3. Auto-save on each message
4. Add conversation list screen
5. Add "New conversation" action

**Dependencies:** None  
**Time Estimate:** 6-8 hours  
**Priority:** P1

---

### 🟠 HIGH-4: Better Error Handling & Retry
**Problem:** Errors are cryptic, no recovery options  
**Value:** Better UX, fewer support issues

**Solution:**
1. Create structured error types:
```dart
sealed class OllamaError {
  const OllamaError();
}

class NetworkError extends OllamaError {
  final String message;
  final bool canRetry;
}

class ModelNotFoundError extends OllamaError {
  final String modelName;
}

class AuthenticationError extends OllamaError {}

class ServerError extends OllamaError {
  final int statusCode;
  final String message;
}
```

2. Add retry logic with exponential backoff
3. Show user-friendly error messages
4. Add "Retry" button in error state
5. Connection status indicator in app bar

**Dependencies:** None  
**Time Estimate:** 4-5 hours  
**Priority:** P1

---

## Part 3: Medium Priority Enhancements

### 🟡 MEDIUM-5: Tool/Function Calling Support
**Problem:** Cannot use tool-enabled models  
**Value:** Enables advanced AI features

**Complexity:** High - requires:
- Tool schema definition
- Function registration system
- Tool invocation handling
- Security considerations

**Recommendation:** Defer to Phase 6 (post-MVP)

---

### 🟡 MEDIUM-6: Embeddings API
**Problem:** No RAG, semantic search, etc.  
**Value:** Enables document Q&A, search

**Solution:**
1. Add embedding models to model list
2. Create `/api/embed` endpoint wrapper
3. Add vector storage (sqlite-vec or similar)
4. Build document upload UI
5. Implement semantic search

**Dependencies:** Conversation persistence (for search context)  
**Time Estimate:** 12-16 hours  
**Priority:** P2 - Phase 6 feature

---

### 🟡 MEDIUM-7: Advanced Model Management
**Problem:** Cannot create/customize models  
**Value:** Power user feature

**Features:**
- Create model from Modelfile
- Edit system prompts
- Copy/rename models
- Push to registry

**Dependencies:** None  
**Time Estimate:** 8-10 hours  
**Priority:** P2

---

## Part 4: Low Priority / Future

### 🟢 LOW-8: JSON Mode / Structured Output
**Dependencies:** Model configuration UI  
**Time Estimate:** 3-4 hours  
**Priority:** P3

### 🟢 LOW-9: Running Models Display (`/api/ps`)
**Dependencies:** None  
**Time Estimate:** 2-3 hours  
**Priority:** P3

### 🟢 LOW-10: Export Conversations
**Dependencies:** Conversation persistence  
**Time Estimate:** 2-3 hours  
**Priority:** P3

### 🟢 LOW-11: Accessibility Features
**Dependencies:** Complete UI refactor  
**Time Estimate:** 20+ hours  
**Priority:** P4

---

## Part 5: Technical Debt

### Technical Improvements Needed
1. **Response metadata display**
   - Show tokens/sec
   - Show memory usage
   - Add performance metrics

2. **Code generation optimization**
   - Parallel build_runner
   - Incremental generation
   - Cache improvements

3. **Test coverage**
   - Unit tests for providers
   - Widget tests for UI
   - Integration tests for API

4. **Documentation**
   - API documentation
   - User guide
   - Development setup guide

---

## Recommended Implementation Order

### Immediate (This Week)
1. **CRITICAL-1: Fix thinking content parsing** ← START HERE
   - Models are completely broken without this
   - Quick fix, high impact
   - Blocking all other work

### Sprint 1 (Next 2 Weeks)
2. **HIGH-2: Model configuration**
   - Essential for good UX
   - Enables proper model testing
   
3. **HIGH-3: Conversation persistence**
   - MVP requirement
   - Enables real usage
   
4. **HIGH-4: Better error handling**
   - Improves reliability
   - Reduces user frustration

### Sprint 2 (Weeks 3-4)
5. **MEDIUM-7: Advanced model management**
   - Power user feature
   - Differentiator from competitors
   
6. **Test coverage**
   - Prevent regressions
   - Enable faster development

### Phase 6 (Future)
7. **MEDIUM-5: Tool calling**
   - Advanced feature
   - Requires careful design
   
8. **MEDIUM-6: Embeddings & RAG**
   - Major feature addition
   - Competitive advantage

---

## Success Metrics

### After Critical Fix
- ✅ Thinking models work without crashes
- ✅ Thinking is displayed in collapsible UI
- ✅ Non-thinking models unaffected

### After Sprint 1
- ✅ Users can control temperature and other parameters
- ✅ Conversations persist across app restarts
- ✅ Error messages are clear and actionable
- ✅ Network errors can be retried

### After Sprint 2
- ✅ Users can create custom models
- ✅ 80%+ code coverage
- ✅ No critical bugs in backlog

### Phase 6 Goals
- ✅ Tool calling works for function-enabled models
- ✅ RAG enables document Q&A
- ✅ Feature parity with Ollama web UI

---

## Dependency Graph

```
CRITICAL-1 (Thinking Fix)
  └─> No dependencies, START HERE
  
HIGH-2 (Model Config)
  └─> No dependencies
  
HIGH-3 (Persistence)
  └─> No dependencies
  └─> Enables: LOW-10 (Export), MEDIUM-6 (Embeddings)
  
HIGH-4 (Errors)
  └─> No dependencies
  
MEDIUM-6 (Embeddings)
  └─> Requires: HIGH-3 (Persistence)
  
MEDIUM-7 (Model Mgmt)
  └─> No dependencies
  
LOW-10 (Export)
  └─> Requires: HIGH-3 (Persistence)
```

---

## Risk Assessment

### Technical Risks
1. **Freezed code generation issues**
   - Mitigation: Make content nullable explicitly
   - Fallback: Manual JSON parsing if needed

2. **SQLite migrations complexity**
   - Mitigation: Use Drift's migration tools
   - Fallback: Clear database on schema change (early stage)

3. **Tool calling security**
   - Mitigation: Sandbox execution, permission system
   - Fallback: Defer until security review complete

### UX Risks
1. **Thinking UI clutters chat**
   - Mitigation: Default collapsed, subtle styling
   - Fallback: Settings toggle to hide thinking

2. **Too many configuration options**
   - Mitigation: Advanced settings section
   - Fallback: Presets (Creative, Balanced, Precise)

---

## Resource Requirements

### Immediate Fix (CRITICAL-1)
- **Developer Time:** 2-3 hours
- **Testing Time:** 1 hour
- **Dependencies:** None
- **External Resources:** None

### Sprint 1 (HIGH-2, 3, 4)
- **Developer Time:** 15-20 hours
- **Testing Time:** 5-8 hours
- **Dependencies:** drift package
- **External Resources:** SQLite documentation

### Sprint 2+
- **Developer Time:** 40+ hours
- **Testing Time:** 15+ hours
- **Dependencies:** TBD based on features
- **External Resources:** Ollama API docs, testing infrastructure

---

## Conclusion

**Start with CRITICAL-1 immediately.** The thinking content parsing bug is blocking real usage of many modern models (kimi-k2.5, deepseek-r1, etc.). This is a quick fix with massive impact.

After that, focus on Sprint 1 features (configuration, persistence, errors) to reach MVP quality. These are essential for real-world usage and have no complex dependencies.

Defer advanced features (tools, embeddings, RAG) to Phase 6 when core functionality is solid and stable.

**Total estimated work:**
- Critical fix: 3 hours
- Sprint 1: 20 hours
- Sprint 2: 40 hours
- Phase 6: 60+ hours

**Grand Total: ~125 hours** to reach full feature parity with Ollama CLI/WebUI.
