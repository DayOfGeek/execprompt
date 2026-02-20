# Thinking / Reasoning Token Research

**Date:** 2026-02-14
**Branch:** `feature/multi-provider-endpoints`
**Purpose:** Document how each major AI provider exposes thinking/reasoning via API, evaluate current ExecPrompt coverage, and determine if further enhancement is warranted.

---

## 1. Provider-by-Provider Analysis

### 1.1 OpenAI (GPT-5, o-series)

**API:** Responses API (preferred) / Chat Completions API (legacy)

| Aspect | Detail |
|---|---|
| **Reasoning visibility** | Reasoning tokens are **NOT** visible by default. Tokens are generated internally and discarded from context. |
| **Reasoning summaries** | Opt-in via `reasoning.summary: "auto"` or `"detailed"`. Returns `summary_text` blocks in output. |
| **Activation** | `reasoning.effort`: `"low"`, `"medium"` (default), `"high"` — controls depth of reasoning |
| **Token tracking** | `usage.output_tokens_details.reasoning_tokens` shows count of hidden reasoning tokens consumed |
| **Encrypted content** | For stateless/ZDR mode, reasoning items have `encrypted_content` for multi-turn continuity |
| **Streaming** | Reasoning summaries stream as output items with `type: "reasoning"` |
| **API shape** | Uses Responses API (`/v1/responses`), **not** Chat Completions. Different request/response shape entirely. |

**Key finding:** OpenAI reasoning is only accessible via the **Responses API**, which has a fundamentally different request/response shape from Chat Completions (`/v1/chat/completions`). ExecPrompt uses Chat Completions exclusively. Migrating to Responses API would be a major architectural change with no cross-provider benefit.

**Verdict:** Not actionable for ExecPrompt without a full API layer rewrite. The Chat Completions path for OpenAI does not expose reasoning tokens at all.

---

### 1.2 Anthropic (Claude 3.7, Claude 4.x)

**API:** Messages API (`/v1/messages`)

| Aspect | Detail |
|---|---|
| **Thinking visibility** | Full thinking output (Claude 3.7) or **summarized** thinking (Claude 4+) |
| **Activation** | `thinking: {type: "enabled", budget_tokens: N}` — explicit opt-in required |
| **Adaptive mode** | Claude Opus 4.6+: `thinking: {type: "adaptive"}` recommended (auto-adjusts budget) |
| **Budget range** | Min 1024 tokens. Budget is a target, not strict limit. |
| **Streaming events** | `content_block_start` → `type: "thinking"`, then `content_block_delta` → `type: "thinking_delta"` with `delta.thinking` text |
| **Signatures** | `signature` field on thinking blocks for verification; must echo back unmodified for tool use |
| **Redaction** | `redacted_thinking` blocks possible — encrypted, non-human-readable, must be passed back |
| **Multi-turn** | Thinking blocks from prior turns auto-stripped (Claude <4.5) or preserved (Claude 4.5+) |
| **Constraints** | `temperature` must be 1.0 or omitted. No pre-fill. No forced tool use. |
| **Interleaved** | Claude 4+: thinking between tool calls via `interleaved-thinking-2025-05-14` beta header |

**Key finding:** This is the most explicitly controllable thinking system. ExecPrompt already activates it correctly with `budget_tokens: 10000`. The main gaps are: (1) budget is hardcoded, (2) temperature conflict potential, and (3) thinking blocks not echoed in multi-turn.

**Verdict:** Current implementation is functional. Minor improvements possible (configurable budget, temperature guard).

---

### 1.3 Google Gemini (2.5 / 3 series)

**Native API:** GenerativeLanguage API with `thinking_config`
**OpenAI-compat:** `generativelanguage.googleapis.com/v1beta/openai/`

| Aspect | Detail |
|---|---|
| **Thinking visibility** | **Thought summaries** (not raw thoughts) via `include_thoughts: true` |
| **Native activation** | `thinking_config: {include_thoughts: true}` + optional `thinking_level` or `thinking_budget` |
| **Thinking levels (Gemini 3)** | `"minimal"`, `"low"`, `"medium"`, `"high"` (default: dynamic `"high"`) |
| **Thinking budget (Gemini 2.5)** | 0–32768 tokens; `-1` for dynamic; `0` to disable |
| **OpenAI-compat activation** | `reasoning_effort`: `"low"`, `"medium"`, `"high"` — maps to thinking levels |
| **OpenAI-compat thoughts** | `extra_body.google.thinking_config.include_thoughts: true` — returns thought summaries |
| **Response format (native)** | `parts[]` with `thought: true` flag for thought summary parts |
| **Response format (OAI-compat)** | Thought summaries in delta — **field name undocumented** for streaming |
| **Thought signatures** | Gemini 3: encrypted thought signatures for multi-turn context (required for function calling) |
| **Cannot disable** | Gemini 3 Pro: thinking cannot be turned off. Gemini 3 Flash: `"minimal"` ≈ nearly off. |

**Key finding:** Gemini via OpenAI-compat supports `reasoning_effort` to control thinking depth, and `include_thoughts: true` to get thought summaries. However, the exact streaming delta field name for thoughts via OpenAI-compat is not well-documented. It likely uses one of our already-covered field names (`thinking`, `thought`, `reasoning`). The `reasoning_effort` parameter can be sent with no harm — if the model doesn't support it, it's ignored.

**Verdict:** Adding `reasoning_effort` to Gemini requests via OpenAI-compat is low-risk and could unlock thought summaries. Worth investigating empirically.

---

### 1.4 DeepSeek (deepseek-reasoner / R1)

**API:** OpenAI-compatible Chat Completions

| Aspect | Detail |
|---|---|
| **Reasoning visibility** | Always present when using `deepseek-reasoner` model |
| **Field name** | `reasoning_content` — at same level as `content` in message/delta |
| **Activation** | **None required** — reasoning is always-on for reasoning models |
| **Configuration** | Not configurable (no budget, effort, or toggle) |
| **Multi-turn** | Previous `reasoning_content` must **NOT** be sent back (API returns 400) |
| **Constraints** | `temperature`, `top_p`, `presence_penalty`, `frequency_penalty` accepted but ignored |
| **max_tokens** | Includes CoT — default 32K, max 64K |
| **Streaming** | `delta.reasoning_content` in stream chunks |

**Key finding:** DeepSeek's approach is the simplest — reasoning is always-on, always returned, and needs no activation. ExecPrompt already captures `reasoning_content` correctly via the OpenAI adapter's 4-field fallback chain.

**Verdict:** Fully working. No changes needed.

---

### 1.5 Ollama (Native API)

**API:** `/api/chat` (native NDJSON) and `/v1/chat/completions` (OpenAI-compat)

| Aspect | Detail |
|---|---|
| **Thinking visibility** | `message.thinking` field in response JSON |
| **Activation** | `"think": true` in request body — **opt-in required** |
| **Compatible models** | deepseek-r1, qwq, qwen3, and other think-capable models |
| **Native streaming** | Each NDJSON chunk: `{"message": {"role": "assistant", "thinking": "...", "content": "..."}}` |
| **OpenAI-compat streaming** | `delta.thinking` in SSE chunks (when routed to OpenAI adapter) |
| **Configuration** | None — binary on/off only |
| **Multi-turn** | Thinking field included in message history if populated |

**Key finding:** Ollama requires explicit `"think": true` in the request body to activate thinking. Without it, thinking-capable models respond directly without showing their reasoning. ExecPrompt's Ollama native adapter currently does **NOT** send `"think": true`.

**Verdict:** **High-impact fix.** Adding `"think": true` to Ollama native requests would immediately enable thinking for all locally-hosted reasoning models.

---

### 1.6 OpenRouter (Proxy)

**API:** OpenAI-compatible Chat Completions (proxies to upstream providers)

| Aspect | Detail |
|---|---|
| **Reasoning visibility** | Provider-dependent; passes through upstream fields |
| **Field names** | `delta.reasoning` (most common), `delta.reasoning_content` (DeepSeek models) |
| **Activation** | Provider-dependent; `reasoning_effort` passed through for models that support it |
| **Configuration** | `verbosity` parameter for response detail level |

**Key finding:** OpenRouter is a pass-through proxy. Field names depend on the upstream model. ExecPrompt's 4-field capture already covers the known field names (`reasoning`, `reasoning_content`, etc.).

**Verdict:** Fully working for capture. No changes needed.

---

### 1.7 Other Notable Models

| Provider/Model | Thinking Approach |
|---|---|
| **Mistral** | No explicit thinking/reasoning API. Models reason internally without exposure. |
| **Meta Llama** | No thinking API. Distilled reasoning models (like R1-distill-Llama) output in `<think>` tags within content, not structured fields. |
| **Qwen (QwQ, Qwen3)** | Via Ollama: uses `think: true` mechanism. Via API: similar to DeepSeek with `reasoning_content`. |

---

## 2. Current ExecPrompt Coverage Matrix

### Thinking Capture (Response Parsing)

| Provider Path | Field Captured | Status |
|---|---|---|
| OpenAI adapter streaming | `delta.thinking`, `delta.reasoning`, `delta.reasoning_content`, `delta.thought` | ✅ Complete |
| OpenAI adapter non-streaming (Gemini tool calls) | Same 4 fields from `message` | ✅ Complete |
| Anthropic adapter streaming | `thinking_delta` → `delta.thinking` | ✅ Complete |
| Ollama native (via fromJson) | `message.thinking` | ✅ Complete |

### Thinking Activation (Request Parameters)

| Provider Path | Activation Sent | Status |
|---|---|---|
| Anthropic | `thinking: {type: "enabled", budget_tokens: 10000}` | ✅ Working (hardcoded budget) |
| Ollama native | **Nothing** — `think: true` not sent | ❌ **GAP** |
| OpenAI adapter (direct OpenAI) | **Nothing** — would need Responses API | ⚠️ Not feasible |
| OpenAI adapter (Gemini) | **Nothing** — `reasoning_effort` not sent | ⚠️ Low priority |
| OpenAI adapter (DeepSeek) | Not needed — always-on for reasoning models | ✅ N/A |
| OpenAI adapter (OpenRouter) | **Nothing** — `reasoning_effort` not sent | ⚠️ Low priority |

### Multi-Turn Thinking Echo

| Provider Path | Thinking Echoed | Status |
|---|---|---|
| All adapters | Previous thinking not sent in message history | ⚠️ Gap (matches API expectations for most providers) |

**Note:** Most providers (DeepSeek, Anthropic <4.5) actively strip or reject thinking from prior turns. Ollama is the exception where thinking *can* be echoed. This is a non-issue for most paths.

---

## 3. Assessment

### What Works Well
1. **4-field capture chain** — Covers all known OpenAI-compat field names for thinking/reasoning
2. **Anthropic activation** — Correctly enables extended thinking with budget
3. **Passive capture via Freezed** — Ollama native path cleanly deserializes thinking
4. **Animated REASONING fold** — UI surfaces captured thinking beautifully regardless of source
5. **ThinkingStatusIndicator** — Provides real-time feedback during active reasoning

### What Needs Improvement
1. **Ollama `think: true`** — Single highest-impact gap. Many local users run deepseek-r1/qwq on Ollama and get no thinking output because we never request it.
2. **Anthropic budget hardcoded** — 10000 tokens is reasonable but not user-configurable. Power users may want to increase for complex tasks or decrease for speed.
3. **Anthropic temperature conflict** — Extended thinking requires temperature=1.0. If user sets a custom temperature, the API may reject the request or silently disable thinking.

### What Is Not Worth Pursuing
1. **OpenAI Responses API** — Completely different API shape. Would require dual-path adapter logic for marginal benefit (summaries only, not raw reasoning).
2. **Gemini native API** — ExecPrompt connects to Gemini via OpenAI-compat. Switching to native Gemini API would lose the unified adapter benefit.
3. **Gemini `extra_body` thinking config** — The `extra_body.google.thinking_config.include_thoughts` path is fragile and poorly documented for streaming. Low confidence it works reliably.
4. **Multi-turn thinking echo** — Most providers explicitly strip or reject prior thinking. Adding echo logic would create provider-specific branching for minimal benefit.

---

## 4. Recommendation

**There is a clear "best effort" implementation path** with exactly **one high-impact change** and **two minor hardening changes**:

| Priority | Change | Impact | Effort |
|---|---|---|---|
| **P0** | Send `"think": true` in Ollama native requests | Unlocks thinking for ALL local reasoning models | ~5 lines |
| **P1** | Guard Anthropic temp when thinking enabled | Prevents silent thinking deactivation | ~3 lines |
| **P2** | Make Anthropic thinking budget configurable (or auto-scale) | Power user flexibility | ~15 lines (UI + wiring) |

The P0 change alone covers the biggest gap. A devplan is warranted.
