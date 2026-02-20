# RC Feature Deep Dive — 2026-02-14

**Branch:** `feature/multi-provider-endpoints`
**Predecessor:** Security hardening + thinking activation (this session)
**Scope:** Three final enhancements before field testing

---

## Overview

Three candidate features promoted from Post-RC to RC-final:

| # | Feature | One-liner |
|---|---------|-----------|
| F1 | Enhanced Conversation Export | Per-conversation export (JSON + Markdown), optional key inclusion, import validation |
| F2 | Token Usage Display | Per-conversation token stats in CONV STATS panel |
| F3 | Full-Text Conversation Search | Search message content, not just titles |

---

## F1: Enhanced Conversation Export

### Current State

| Capability | Status | Location |
|---|---|---|
| Export ALL conversations (JSON) | ✅ Exists | Settings > Data Management |
| Import from JSON file | ✅ Exists | Settings > Data Management |
| `share_plus` wired up | ✅ Exists | Used by bulk export |
| `file_picker` wired up | ✅ Exists | Used by import |
| Export SINGLE conversation | ❌ Missing | — |
| Export as Markdown | ❌ Missing | — |
| Per-conversation share | ❌ Missing | — |
| Export format choice | ❌ Missing | — |
| Secure key handling in export | ❌ Missing | Export has no API keys (correct default) |

**Existing export method** (`AppDatabase.exportAllData()`): Iterates all conversations, serializes to JSON with all message fields (content, thinking, images as base64, tool calls, tool names). Does NOT include any API keys or endpoint configuration — data only.

**Existing import method** (`AppDatabase.importData()`): Creates new conversations from JSON, preserves timestamps, handles missing fields gracefully. No deduplication — re-importing creates duplicates.

### Gap Analysis

| Gap | Impact | Effort |
|-----|--------|--------|
| No single-conversation export | Users must export ALL to share one conversation | Low — add `exportConversation(int id)` method |
| No Markdown format | JSON is unreadable for sharing with people | Medium — build Markdown renderer |
| No export in sidebar/drawer | Discovery problem — users don't know export exists | Low — add action to long-press sheet |
| No export from chat screen | Can't export while viewing a conversation | Low — add app bar action or `[EX]` term action |
| Import creates duplicates | Re-importing same file doubles all conversations | Medium — add hash/dedup check |
| No export progress indicator | Large exports may hang with no feedback | Low — add loading state |

### Recommendation: What to Build

**Tier 1 (RC):**
1. **Single-conversation export** — Add `exportConversation(int id)` to `AppDatabase`
2. **Format choice dialog** — "Export as: [JSON] [Markdown]" when user taps export
3. **Markdown renderer** — Convert conversation to readable Markdown with role headers, code blocks preserved, thinking sections collapsed
4. **Export action in sidebar** — Add `[EX] Export` to long-press bottom sheet on conversation tiles (both `conversation_panel.dart` and `conversation_drawer.dart`)
5. **Export action in app bar** — Add share/export icon button to app bar actions when a conversation is loaded

**Tier 2 (Post-RC):**
- Import deduplication (hash-based)
- Selective export (pick which conversations to export)
- Export with endpoint config (the "include secure keys" option — requires careful UX to prevent accidental key exposure)

### Design: Markdown Export Format

```markdown
# Conversation: {title}
**Model:** {modelName}
**Date:** {createdAt}
**Messages:** {count}

---

## User — 2026-02-14 10:30:15

What is the meaning of life?

---

## Assistant — 2026-02-14 10:30:18

<details><summary>Thinking</summary>

The user is asking a philosophical question...

</details>

The meaning of life is a deeply personal question...

---

## User — 2026-02-14 10:31:00

Can you elaborate?

---
```

### Mobile vs Tablet Impact

| Element | Phone/Tablet_S | Tablet_L/Desktop |
|---------|----------------|------------------|
| Export in sidebar | Long-press → bottom sheet adds `[EX] Export` | Same, in persistent sidebar |
| Export in app bar | Share icon in app bar actions | Same, or in detail panel |
| Format dialog | Bottom sheet: "JSON / Markdown" | Same dialog |
| Share mechanism | `Share.shareXFiles()` → native share sheet | Same (Linux: saves to file) |

**No responsive divergence needed.** The long-press bottom sheet and app bar action patterns are already responsive. The `share_plus` package handles platform differences.

### Files Changed

| File | Change | Lines |
|------|--------|-------|
| `lib/data/database/app_database.dart` | Add `exportConversation(int id)`, `exportConversationAsMarkdown(int id)` | ~40 |
| `lib/presentation/widgets/conversation_panel.dart` | Add Export action to long-press bottom sheet | ~15 |
| `lib/presentation/widgets/conversation_drawer.dart` | Same | ~15 |
| `lib/presentation/screens/adaptive_shell.dart` | Add export IconButton to app bar actions | ~20 |
| `lib/domain/providers/chat_provider.dart` | Add `exportCurrentConversation()` method or expose conversation ID | ~5 |

**Total estimate:** ~95 lines new code, ~0 lines removed

---

## F2: Token Usage Display (Per-Conversation)

### Current State

| Capability | Status | Location |
|---|---|---|
| Ollama token fields in model | ✅ Parsed | `ChatResponse.evalCount`, `promptEvalCount`, durations |
| OpenAI `usage` block | ❌ Discarded | `openai_adapter.dart` never reads `usage` field |
| Anthropic `usage` block | ❌ Discarded | `anthropic_adapter.dart` never reads `usage` from SSE events |
| Token data consumed by UI | ❌ None | `chat_provider.dart` ignores all token fields |
| Token display in CONV STATS | ❌ Missing | Only shows "Messages" count and "Status" |
| Token data persisted to DB | ❌ Missing | `Messages` table has no token columns |

### Gap Analysis

| Gap | Impact | Effort |
|-----|--------|--------|
| OpenAI adapter discards `usage` | No token data for OpenAI/OpenRouter/Gemini models | Medium — parse `usage` from final SSE chunk and non-streaming responses |
| Anthropic adapter discards `usage` | No token data for Claude models | Medium — parse `usage` from `message_start` + `message_delta` events |
| ChatResponse fields unused | Data flows in from Ollama but is never surfaced | Low — wire to state |
| No DB persistence | Token counts lost on app restart | Medium — schema migration (v2→v3) to add columns |
| No aggregation | Need per-conversation totals | Low — SUM query or in-memory accumulation |

### Provider-Specific Token Data

| Provider | Input Tokens | Output Tokens | Source |
|----------|-------------|---------------|--------|
| **Ollama** | `promptEvalCount` (final chunk) | `evalCount` (final chunk) | Already in ChatResponse model |
| **OpenAI** | `usage.prompt_tokens` (final chunk or non-streaming) | `usage.completion_tokens` | SSE: in `[DONE]`-adjacent chunk; Non-streaming: in response body |
| **Anthropic** | `usage.input_tokens` (in `message_start`) | `usage.output_tokens` (in `message_delta`) | Two separate SSE events |
| **Gemini** (via OpenAI compat) | `usage.prompt_tokens` | `usage.completion_tokens` | Same as OpenAI path |
| **OpenRouter** | `usage.prompt_tokens` | `usage.completion_tokens` | Same as OpenAI path |

### Recommendation: What to Build

**Tier 1 (RC) — In-Memory Only, No Schema Migration:**
1. **Capture tokens in all three adapters** — Map provider-specific fields to `ChatResponse.evalCount` / `promptEvalCount`
2. **Accumulate per-conversation totals in ChatState** — Add `totalInputTokens` and `totalOutputTokens` fields
3. **Display in CONV STATS** — Add `_StatRow` entries for "Input Tokens", "Output Tokens" in both `DetailPanel` and `MobileDetailDrawer`
4. **Display "N/A" gracefully** — When provider doesn't return usage data (some models)

**Tier 2 (Post-RC) — Persistent:**
- Schema migration to add `inputTokens` / `outputTokens` columns to `Messages` table
- Historical token aggregation across conversations
- Cost estimation (requires token pricing data per model)

### Design: Token Display

In CONV STATS section (both `DetailPanel` and `MobileDetailDrawer`):

```
▸ CONV STATS
  Messages      12
  Status        IDLE
  In Tokens     1,247
  Out Tokens    3,891
  Total         5,138
```

When no token data is available (model doesn't report it): show `—` instead of `0`.

### Mobile vs Tablet Impact

| Element | Phone/Tablet_S | Tablet_L/Desktop |
|---------|----------------|------------------|
| Token display | In `MobileDetailDrawer` CONV STATS section | In `DetailPanel` CONV STATS section |
| Access | Tap ⚙ tune icon → open endDrawer | Always visible in persistent panel |

**Minimal responsive impact.** Both widgets already have identical CONV STATS sections with `_InfoRow`/`_StatRow` pattern. Adding 2-3 more rows is mechanical.

### Files Changed

| File | Change | Lines |
|------|--------|-------|
| `lib/data/services/openai_adapter.dart` | Parse `usage` from final SSE chunk and non-streaming response | ~20 |
| `lib/data/services/anthropic_adapter.dart` | Parse `usage` from `message_start` and `message_delta` events | ~15 |
| `lib/domain/providers/chat_provider.dart` | Add token accumulation to `ChatState`, update in stream listener | ~25 |
| `lib/presentation/widgets/detail_panel.dart` | Add token `_StatRow` entries | ~20 |
| `lib/presentation/widgets/mobile_detail_drawer.dart` | Add token `_InfoRow` entries | ~20 |

**Total estimate:** ~100 lines new code, ~0 lines removed

---

## F3: Full-Text Conversation Search

### Current State

| Capability | Status | Location |
|---|---|---|
| Search TextField in sidebar | ✅ Exists | Both `conversation_panel.dart` and `conversation_drawer.dart` |
| `conversationSearchQueryProvider` | ✅ Exists | `database_provider.dart` |
| `filteredConversationsProvider` | ✅ Exists | Client-side `title.contains(query)` |
| Search message content | ❌ Missing | Only searches conversation titles |
| Database-level search query | ❌ Missing | No SQL LIKE or FTS |
| Search result highlights | ❌ Missing | — |
| Search match context | ❌ Missing | No preview of matching message |

### Gap Analysis

| Gap | Impact | Effort |
|-----|--------|--------|
| Title-only search | Can't find conversations by what was discussed | HIGH — this is the whole feature gap |
| Client-side filtering | Loads ALL conversations into memory, filters in Dart | Medium for small DBs, problematic at scale |
| No DB search query | No SQL LIKE or FTS index | Medium — add query method |
| No match preview | User can't see WHY a conversation matched | Medium — need to extract matching snippet |
| No highlight | Search terms not visually highlighted in results | Low — cosmetic |

### Architecture Options

**Option A: Client-Side Content Search (Simple)**
- Load all messages for all conversations, search in Dart
- Pro: No schema changes, no migration
- Con: O(n*m) — scales poorly with many conversations
- Verdict: Fine for RC with < 500 conversations (typical power user range)

**Option B: SQL LIKE Query (Medium)**
- Add `searchConversations(String query)` to `AppDatabase`
- Query: `SELECT DISTINCT c.* FROM conversations c JOIN messages m ON m.conversationId = c.id WHERE c.title LIKE '%query%' OR m.content LIKE '%query%' ORDER BY c.updatedAt DESC`
- Pro: Database-level, reasonably efficient with index on `messages.conversationId`
- Con: No ranking, no partial word matching
- Verdict: Best balance for RC

**Option C: SQLite FTS5 (Complex)**
- Add FTS5 virtual table with triggers to keep in sync
- Pro: Fast ranked full-text search, prefix matching
- Con: Schema migration, sync triggers, Drift FTS setup complexity
- Verdict: Post-RC — overkill for initial release

### Recommendation: Option B (SQL LIKE)

1. **Add `searchConversations(String query)` to `AppDatabase`** — SQL JOIN + LIKE on both title and message content
2. **Add `searchMessagesInConversation(int convId, String query)`** — For showing which messages matched
3. **Update `filteredConversationsProvider`** — When query is non-empty, call DB method instead of client-side filter
4. **Add match snippet preview** — Show first matching message excerpt under the conversation title in the tile
5. **Debounce search input** — 300ms debounce to avoid hammering DB while typing

### Design: Enhanced Search UI

Current conversation tile:
```
▸ What is the meaning of life?
  claude-3.5-sonnet · 2h ago
```

With search active and matching a MESSAGE:
```
▸ What is the meaning of life?
  "...the meaning of life is deeply personal..."
  claude-3.5-sonnet · 2h ago
```

The snippet line appears ONLY when search is active and the match came from message content (not title). Max ~60 chars with ellipsis.

### Mobile vs Tablet Impact

| Element | Phone/Tablet_S | Tablet_L/Desktop |
|---------|----------------|------------------|
| Search field | Already in drawer | Already in sidebar |
| Result tiles | Same tile + snippet | Same |
| Debounce | Same 300ms | Same |
| Snippet line | May need smaller font on phone | Standard font on tablet+ |

**Minimal responsive impact.** The search field and tile structure are already shared between `conversation_panel.dart` and `conversation_drawer.dart`. Adding a snippet line to the tile is identical in both.

### Files Changed

| File | Change | Lines |
|------|--------|-------|
| `lib/data/database/app_database.dart` | Add `searchConversations(String query)`, `searchMessagesInConversation()` | ~25 |
| `lib/domain/providers/database_provider.dart` | Update `filteredConversationsProvider` to use DB search | ~20 |
| `lib/presentation/widgets/conversation_panel.dart` | Add snippet line to `_PanelConversationTile`, debounce input | ~25 |
| `lib/presentation/widgets/conversation_drawer.dart` | Same for `_ConversationTile` | ~25 |

**Total estimate:** ~95 lines new code, ~10 lines replaced

---

## Cross-Feature Summary

### Combined Effort Estimate

| Feature | New Lines | Modified Lines | Files Touched | Risk |
|---------|-----------|----------------|---------------|------|
| F1: Export | ~95 | ~0 | 5 | Low — additive, uses existing infra |
| F2: Token Usage | ~100 | ~0 | 5 | Medium — adapter parsing changes, must handle missing data gracefully |
| F3: Search | ~95 | ~10 | 4 | Low — DB query + UI wiring |
| **Total** | **~290** | **~10** | **10 unique** | |

### Dependency Graph

```
F1 (Export) ──── independent
F2 (Tokens) ──── independent
F3 (Search) ──── independent
```

No feature depends on another. Can be implemented and committed in any order.

### Recommended Implementation Order

| Order | Feature | Rationale |
|-------|---------|-----------|
| 1 | F3: Search | Highest user impact, lowest risk, enhances existing UI |
| 2 | F1: Export | High value, leverages existing code, mostly additive |
| 3 | F2: Tokens | Medium value, touches adapters (riskiest), purely informational |

### Commit Plan

| Commit | Scope |
|--------|-------|
| 1 | F3: DB search method + provider wiring |
| 2 | F3: UI — snippet line in conversation tiles, debounce |
| 3 | F1: DB single-conversation export (JSON + Markdown) |
| 4 | F1: UI — export actions in sidebar, app bar, format dialog |
| 5 | F2: Adapter token capture (OpenAI + Anthropic) |
| 6 | F2: ChatState accumulation + CONV STATS display |

---

## Decision Points

1. **Export: Include thinking content in Markdown export?** — Recommend yes, in `<details>` collapsed blocks.
2. **Export: Include tool call/result messages in Markdown?** — Recommend yes, formatted as code blocks.
3. **Tokens: Show "Total" (input + output) or keep separate?** — Recommend show all three: In / Out / Total.
4. **Tokens: Persist to DB now or defer?** — Recommend defer to post-RC. In-memory only for RC.
5. **Search: Add index on `messages.content`?** — Recommend no for RC. SQLite LIKE with JOIN is fast enough for typical usage (< 10k messages). Add FTS5 post-RC if needed.
6. **Search: Debounce time?** — Recommend 300ms. Fast enough to feel responsive, slow enough to avoid unnecessary queries.
