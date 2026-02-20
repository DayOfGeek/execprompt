# ExecPrompt — Release Candidate Development Plan

**Version:** RC-1  
**Date:** February 10, 2026  
**Status:** PROPOSAL — NO CODE CHANGES  
**Base:** Beta build (commit bd7bb2b)

---

## Executive Summary

Beta testing on physical devices revealed 6 polish/bug issues (including 1 critical) and 1 strategic feature request (tablet/landscape support). This document defines the RC scope, performs a gap analysis on each item, and provides a feasibility assessment for the tablet layout question — including whether it can coexist in the same APK or requires a separate deliverable. Includes a deep-dive design specification for 13" tablet UX (OnePlus Pad 3 class devices).

---

## RC-1: Issue Tracker

| # | Issue | Severity | Effort | Phase |
|---|-------|----------|--------|-------|
| 1 | Models screen — no guidance on fresh install (no connection) | HIGH | Small | RC-1A |
| 2 | Settings — remove "Built with Flutter" footer text | LOW | Trivial | RC-1A |
| 3 | Image picker — first-launch freeze / permission UX | MEDIUM | Small | RC-1A |
| 4 | Image flicker in message bubble during streaming/thinking | MEDIUM | Medium | RC-1A |
| 5 | Copy confirmation + Delete confirmation dialog | MEDIUM | Small | RC-1A |
| 6 | STOP generation — doesn't cancel HTTP, jams system | **CRITICAL** | Medium | RC-1A |
| 7 | Tablet/landscape adaptive layout (13" deep-dive) | FEATURE | Large | RC-1B |

**Phase RC-1A** = Bug fixes + polish (ship-blocking or quality-of-life)  
**Phase RC-1B** = Tablet layout enhancement (strategic, requires deeper analysis)

---

## RC-1A: Bug Fixes & Polish

---

### Issue 1: Models Screen — Fresh Install UX

**Problem:**  
On a fresh install with no connection configured, the models screen shows a raw error: `"Unknown error: The connection errored..."`. There is no indication that the user needs to configure a server first, and no way to navigate to settings from this screen.

**Current State (Gap Analysis):**
- `models_screen.dart` uses `modelsAsync.when(error:)` which renders the raw `error.toString()` — no parsing, no friendly message
- Only action in error state is `[RETRY]` — no link to settings
- No distinction between "no connection configured" vs "server unreachable" vs "auth failed"
- The server URL is stored in `flutter_secure_storage` via `settingsProvider` — we can check if it's empty/default

**Proposed Fix:**
1. Check if server URL is empty/default before fetching models — if so, render a "first run" welcome state:
   ```
   ▸ NO SERVER CONFIGURED
   
   Configure your Ollama server
   connection to get started.
   
   [CONFIGURE →]
   ```
2. For actual connection errors, parse common error types and show friendlier messages:
   - Connection refused → `"Server unreachable at {url}"`
   - Timeout → `"Connection timed out"`
   - Other → current raw error (truncated)
3. Add `[SETTINGS]` button alongside `[RETRY]` in all error states

**Effort:** ~30 min  
**Risk:** LOW — isolated to one screen, no architectural changes  
**Feasibility:** ✅ FULLY FEASIBLE

---

### Issue 2: Remove "Built with Flutter" Footer

**Problem:**  
The settings screen footer shows `"Built with Flutter"` — unnecessary for an end-user app and looks unpolished.

**Current State (Gap Analysis):**
- Located at the very bottom of `settings_screen.dart` — two `Text` widgets in a `Center`/`Column`:
  - `'ExecPrompt v1.0.0'` (fontSize 11)
  - `'Built with Flutter'` (fontSize 10)

**Proposed Fix:**
- Remove the `'Built with Flutter'` text widget entirely
- Keep `'ExecPrompt v1.0.0'` as the sole footer — possibly styled as `'▸ ExecPrompt v1.0.0-rc1'` to match the terminal aesthetic

**Effort:** ~5 min  
**Risk:** NONE  
**Feasibility:** ✅ TRIVIAL

---

### Issue 3: Image Picker — First-Launch Freeze

**Problem:**  
First time opening the photo picker, the app appears to freeze momentarily while Android's permission dialog / media picker spins up. A system toast says "ExecPrompt only has access to the pictures you select." Subsequent uses work fine.

**Current State (Gap Analysis):**
- `chat_input.dart` creates `ImagePicker()` as a field — no pre-warming
- No runtime permission request before invoking the picker (relies entirely on `image_picker` plugin internals)
- No loading indicator while the picker is initializing
- `AndroidManifest.xml` declares `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` — these are **ignored on Android 13+** (API 33+). Missing `READ_MEDIA_IMAGES` permission for modern Android
- The "only has access to pictures you select" message is Android 14's built-in photo picker UX — this is **expected behavior** and not a bug

**Proposed Fix:**
1. Add `READ_MEDIA_IMAGES` permission to `AndroidManifest.xml` for Android 13+ compatibility
2. Show a brief loading/spinner overlay when the picker is first invoked to mask the cold-start delay
3. Consider calling `ImagePicker().retrieveLostData()` on init to pre-warm the picker subsystem
4. The "only has access to pictures you select" message is an **Android system dialog** — we cannot suppress it, and it's actually good UX (privacy-first). No action needed on that front.

**Effort:** ~20 min  
**Risk:** LOW — standard Android permission handling  
**Feasibility:** ✅ FULLY FEASIBLE  
**Note:** The freeze is primarily Android's cold-start of the photo picker activity. The loading indicator masks it; the root cause is platform-level and not something we control.

---

### Issue 4: Image Flicker During Streaming/Thinking

**Problem:**  
When a message contains an attached image, the image visually "blinks" or flickers while the response is streaming — especially during the thinking phase when content updates rapidly.

**Current State (Gap Analysis):**
- `MessageBubble` is a **`StatelessWidget`** — it rebuilds entirely on every parent state change
- During streaming, the `ChatNotifier` updates state on every received token (potentially 20-50+ times per second)
- Each rebuild calls `base64Decode(img)` on the raw base64 string — re-decoding the image bytes on every single frame
- `Image.memory(bytes)` with freshly decoded bytes = Flutter sees a "new" image each frame = flicker
- No `const` optimization possible since data is runtime
- The blinking cursor animation adds additional rebuilds on top of streaming rebuilds

**Root Cause:** Re-decoding base64 → new `Uint8List` → `Image.memory` treats it as new image data each rebuild.

**Proposed Fix:**
1. **Cache decoded image bytes** — convert `MessageBubble` to a `StatefulWidget` (or use a `StatelessWidget` with cached data). Decode base64 images once in `initState` / `didUpdateWidget` only when the image list actually changes, and store the decoded `Uint8List` results
2. **Use `Image.memory` with `gaplessPlayback: true`** — prevents the blank flash between image rebuilds
3. **Wrap the image section in a `RepaintBoundary`** — isolates image rendering from the rest of the message bubble's rebuild cycle
4. Optionally: extract the image row into its own widget with `shouldRebuild` logic

**Effort:** ~45 min  
**Risk:** LOW — localized to `message_bubble.dart`, well-understood Flutter optimization  
**Feasibility:** ✅ FULLY FEASIBLE

---

### Issue 5: Copy Confirmation + Delete Confirmation Dialog

**Problem:**  
- Copy `[CP]` — already shows a SnackBar + haptic, which is fine. User confirms this works.
- Edit `[ED]` — user says "not needed, ok for the most part" — no changes.
- Remove `[RM]` — **no confirmation dialog**. Tapping `[RM]` immediately deletes the message with no undo. Easy to accidentally delete.

**Current State (Gap Analysis):**
- `[CP]` action: calls `Clipboard.setData()` → shows SnackBar `'> Copied to clipboard'` (1s) + haptic ✅
- `[RM]` action: directly calls `onDelete!()` which calls `chatProvider.removeMessage(id)` — message gone, no confirmation, no undo
- The conversation delete in the drawer DOES have a confirmation `AlertDialog` — so the pattern already exists in the codebase

**Proposed Fix:**
1. **Copy `[CP]`**: Change the feedback to be more prominent — either a brief text change on the button itself (`[CP]` → `[OK]` for 1.5s, like we did for code block copy) or keep the current SnackBar. User seems OK with current behavior, so light touch only.
2. **Remove `[RM]`**: Add a confirmation `AlertDialog` before deletion, matching the style of the existing conversation delete dialog:
   ```
   ▸ DELETE MESSAGE
   
   Remove this message from the
   conversation? This cannot be undone.
   
   [CANCEL]  [DELETE]
   ```
   Styled with CyberTerm colors (danger/error color for DELETE button).

**Effort:** ~20 min  
**Risk:** NONE — pattern already exists in conversation_drawer.dart  
**Feasibility:** ✅ FULLY FEASIBLE

---

### Issue 6: STOP Generation — Broken Cancel Pipeline

**Problem:**  
Hitting STOP during streaming doesn't actually stop the model output. The UI may jam — the STOP button stays visible, input remains disabled, and the Ollama server continues burning GPU/CPU generating text that nobody is reading. Subsequent messages can queue up behind the orphaned request, making the system feel "locked."

**Current State (Gap Analysis) — 5 Compounding Bugs Found:**

#### Bug #1 (ROOT CAUSE): No `CancelToken` on the HTTP Request
- `ollama_api_service.dart` uses `_dio.post<ResponseBody>()` to open the streaming connection
- **Zero `CancelToken` usage anywhere in the entire codebase** — confirmed by grep
- When `stopGeneration()` is called, it cancels the Dart `StreamSubscription` — but the underlying HTTP connection stays **wide open**
- The Ollama server has no way to know the client wants to stop — it continues generating the full response
- Tokens accumulate in OS/Dart socket buffers, and the GPU keeps running inference
- If the user sends a new message, a **second concurrent request** starts while the first is still being served — most Ollama models serialize inference, so requests queue and the system "jams"

#### Bug #2: `onDone` May Never Fire After Cancel
- `stopGeneration()` relies on the stream's `onDone` callback to finalize state (set `isLoading = false`, save partial content, clear streaming state)
- Dart's contract: calling `.cancel()` on a `StreamSubscription` does **NOT guarantee** `onDone` fires
- With `async*` generators (which is what `streamChat()` uses), cancel pauses the generator at the `yield` point — `onDone` may or may not execute depending on internal cleanup timing
- **Result:** `isLoading` can get stuck at `true` permanently — the UI shows STOP button forever, input is disabled, user is locked out

#### Bug #3: `stopGeneration()` Doesn't Reset State Directly
```dart
void stopGeneration() {
    _currentStreamSubscription?.cancel();
    _currentStreamSubscription = null;
    // The onDone handler will finalize any partial content
}
```
- This method only cancels the subscription and nulls the reference
- It does **NOT**: set `isLoading = false`, clear `currentStreamingContent`, clear `currentStreamingThinking`, or save partial accumulated text
- All cleanup is delegated to `onDone` — which per Bug #2 may never fire

#### Bug #4: 60-Second `receiveTimeout` on Streaming
- `ollama_api_service.dart` sets `receiveTimeout: Duration(seconds: 60)` on the Dio client
- For streaming LLM responses from large reasoning models (thinking can take 2-5+ minutes between tokens), this timeout can prematurely kill legitimate generations
- After cancel, the orphaned response may eventually hit this timeout and throw into a dead error handler

#### Bug #5: No Concurrent Request Guard
- `sendMessage()` has no check for in-flight requests
- If `isLoading` gets stuck (Bug #2) and the user manages to trigger a retry or new chat, a second HTTP stream starts while the first is still open
- Ollama typically processes one model request at a time — concurrent requests serialize and queue, making everything slow

**Proposed Fix (Complete Pipeline Rewrite):**

1. **Add `CancelToken` to the API service:**
   ```dart
   // ollama_api_service.dart
   CancelToken? _activeCancelToken;
   
   Stream<ChatResponse> streamChat(ChatRequest request) async* {
     _activeCancelToken = CancelToken();
     try {
       final response = await _dio.post<ResponseBody>(
         '/api/chat',
         data: request.toJson(),
         options: Options(responseType: ResponseType.stream),
         cancelToken: _activeCancelToken,
       );
       // ... yield loop ...
     } finally {
       _activeCancelToken = null;
     }
   }
   
   void cancelActiveRequest() {
     _activeCancelToken?.cancel('User stopped generation');
   }
   ```

2. **Rewrite `stopGeneration()` to be self-sufficient:**
   ```dart
   void stopGeneration() {
     // 1. Cancel the HTTP request at the wire level
     _apiService.cancelActiveRequest();
     
     // 2. Cancel the stream subscription
     _currentStreamSubscription?.cancel();
     _currentStreamSubscription = null;
     
     // 3. Save partial content as a message (don't rely on onDone)
     if (state.isLoading) {
       _finalizePartialMessage();
       state = state.copyWith(
         isLoading: false,
         currentStreamingContent: null,
         currentStreamingThinking: null,
       );
     }
   }
   ```

3. **Add `try/finally` in the `async*` generator** to ensure `ResponseBody.stream` is closed on cancellation

4. **Remove or significantly increase `receiveTimeout`** for streaming requests (set to 0 / unlimited for the streaming endpoint, keep timeouts for non-streaming calls like model list)

5. **Add in-flight guard** at the top of `sendMessage()` — if a request is in progress, cancel it first before starting the new one

**Effort:** ~1.5 hours  
**Risk:** MEDIUM — touches the core streaming pipeline, but all changes are well-understood patterns (Dio `CancelToken` is documented, state cleanup is straightforward)  
**Feasibility:** ✅ FULLY FEASIBLE  
**Priority:** ⚠️ **SHIP-BLOCKING** — this is the most critical bug. An unresponsive STOP button that jams the system is a fundamental UX failure.

---

## RC-1B: Tablet / Landscape Adaptive Layout

### The Question

> Can we add tablet/landscape support to the existing codebase, or do we need a separate app?

---

### Gap Analysis: Current Responsive State

| Aspect | Current State |
|--------|--------------|
| `MediaQuery` usage | **ZERO** — none anywhere in `lib/` |
| `LayoutBuilder` usage | **ZERO** |
| Responsive breakpoints | **NONE** |
| Orientation handling | **NONE** — AndroidManifest does NOT lock orientation, so rotation works but layout doesn't adapt |
| Tablet-specific code | **NONE** |
| Drawer implementation | Standard overlay `Drawer` — not a persistent sidebar |
| Font sizing | Hardcoded throughout (fontSize: 11, 12, 13, 14, etc.) |
| Padding/margins | Hardcoded values (EdgeInsets.all(16), etc.) |

### Feasibility Assessment: Single APK vs Separate App

#### Option A: Single APK with Adaptive Layout (RECOMMENDED ✅)

**How it works:**  
Flutter has first-class support for adaptive layouts. A single codebase and single APK can serve both phones and tablets using `MediaQuery` / `LayoutBuilder` breakpoints. This is the standard approach used by Google's own Flutter apps (Gmail, Drive, etc.).

**What changes:**

1. **Responsive shell** — Create an `AdaptiveShell` widget that wraps the app:
   - **Phone (width < 600dp):** Current layout exactly as-is. Overlay drawer. Full-screen navigation.
   - **Tablet portrait (600-840dp):** Slightly wider content area, same layout. Consider showing drawer as a rail.
   - **Tablet landscape (> 840dp):** Side-by-side layout — persistent conversation sidebar (left, ~320dp) + chat area (remaining space). Settings/Models as dialogs or sheets instead of full-screen pushes.

2. **Font scaling** — Use `MediaQuery.textScaleFactor` or custom breakpoint-based sizing:
   - Phone: current sizes (12-14sp)
   - Tablet: slightly larger (14-16sp) for readability at arm's length

3. **ConversationDrawer → ConversationPanel:**
   - On phone: stays as overlay `Drawer` (current behavior, untouched)
   - On tablet landscape: renders as a persistent `NavigationRail` or side panel within a `Row`
   - Same widget internally, different parent layout

4. **Message bubbles** — Add `maxWidth` constraint so messages don't stretch the full width of a 10" tablet:
   ```dart
   ConstrainedBox(constraints: BoxConstraints(maxWidth: 720))
   ```

**Impact on existing mobile app:** **ZERO.** All phone-width checks fall through to the current layout. The mobile experience is completely untouched.

**Play Store:** **Single listing, single APK.** Android handles phone vs tablet automatically. You can upload tablet screenshots separately in the Play Console.

**Effort:** ~4–6 hours  
**Risk:** LOW — all changes are additive, wrapped in width breakpoints  
**Feasibility:** ✅ FULLY FEASIBLE

#### Option B: Separate Tablet App (NOT RECOMMENDED ❌)

**How it would work:**  
Fork the codebase, create a second Flutter project with a different package name (e.g., `com.dayofgeek.execprompt_tablet`), optimize layouts for tablet.

**Problems:**
- **Double maintenance** — every bug fix, feature, and dependency update must be applied to both codebases
- **Divergent UIs** — they will inevitably drift apart over time
- **Play Store confusion** — users on convertible/foldable devices wouldn't know which to install
- **No technical benefit** — Flutter's adaptive layout system handles this natively in one codebase
- **Foldable devices** — modern phones like Galaxy Z Fold unfold from phone to tablet size. A single adaptive app handles this seamlessly; two separate apps cannot.

**Verdict:** There is no technical or practical reason to split. A single adaptive codebase is strictly superior.

#### Option C: Tablet Support as a Future Phase (DEFERRED)

If RC-1B feels too large for the RC milestone, tablet layout can be deferred to v1.1 without any risk. The app already works on tablets — it just doesn't optimize the layout. Users can install and use it today on a tablet in portrait mode with no issues.

---

### Recommended Tablet Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AdaptiveShell                     │
│  ┌──────────────┬──────────────────────────────────┐ │
│  │              │                                  │ │
│  │  Conversation│         Chat Area                │ │
│  │  Sidebar     │                                  │ │
│  │  (320dp)     │    ┌──────────────────────┐      │ │
│  │              │    │  Message Bubbles      │      │ │
│  │  ▸ Search    │    │  (maxWidth: 720dp)    │      │ │
│  │  ▸ Today     │    │                      │      │ │
│  │    Chat 1  ◄─┤───▶│  [USR] Hello...      │      │ │
│  │    Chat 2    │    │  [SYS] Response...   │      │ │
│  │  ▸ Yesterday │    │                      │      │ │
│  │    Chat 3    │    └──────────────────────┘      │ │
│  │              │                                  │ │
│  │  ▸ Settings  │    ┌──────────────────────┐      │ │
│  │  ▸ Models    │    │  Chat Input           │      │ │
│  │              │    └──────────────────────┘      │ │
│  └──────────────┴──────────────────────────────────┘ │
│              TABLET LANDSCAPE (> 840dp)              │
└─────────────────────────────────────────────────────┘

┌──────────────────┐
│   ☰  ExecPrompt    │
│                  │
│  Message Bubbles │
│  (full width)    │
│                  │
│  [USR] Hello...  │
│  [SYS] Response  │
│                  │
│  ┌──────────────┐│
│  │ Chat Input   ││
│  └──────────────┘│
│  PHONE (< 600dp) │
│  (UNCHANGED)     │
└──────────────────┘
```

**Key principle:** The phone layout is the DEFAULT. Tablet layout is purely additive — wider screens get more, narrower screens get exactly what exists today.

---

## RC-1B Deep Dive: 13" Tablet UX Design (OnePlus Pad 3 Class)

### Target Device Profile

| Spec | Value |
|------|-------|
| Device | OnePlus Pad 3 (and similar 12-13" tablets) |
| Screen | 13.2" LCD, 3000 x 2120 px |
| Aspect Ratio | ~1.415:1 — nearly A4 paper proportions |
| Density | ~274 PPI |
| Logical Resolution | ~1500 x 1060 dp (at ~2x density) |
| Orientation | Landscape primary (keyboard/kickstand use), portrait secondary |
| Interaction | Touch + optional stylus + optional keyboard |
| Context | Held at arm's length or on desk — not close to face like phone |

### Design Philosophy

A 13" tablet is not "a big phone" — it's closer to a laptop screen. At 1500x1060 dp in landscape, we have roughly **4x the usable area** of a typical phone (390x844 dp). Stretching the phone layout to fill this space would look absurd — a single chat message spanning 1500dp of width is unreadable. The design must **redistribute content into zones** that exploit the space.

Our CyberTerm aesthetic actually **benefits enormously** from a large screen — it can evoke a full retro workstation: command terminal with side panels, like a proper hacker cockpit.

### Breakpoint Tiers

```
┌─────────────┬───────────────┬──────────────────────────────────┐
│ Tier        │ Width Range   │ Layout                           │
├─────────────┼───────────────┼──────────────────────────────────┤
│ PHONE       │ < 600dp       │ Current layout (UNCHANGED)       │
│ TABLET-S    │ 600 – 840dp   │ Wider margins, maxWidth on chat  │
│ TABLET-L    │ 840 – 1200dp  │ Persistent sidebar + chat        │
│ DESKTOP     │ > 1200dp      │ Sidebar + chat + detail panel    │
└─────────────┴───────────────┴──────────────────────────────────┘
```

The OnePlus Pad 3 in landscape lands squarely in **DESKTOP** tier (~1500dp wide). In portrait it's ~1060dp — TABLET-L.

### Layout: TABLET-L (840-1200dp) — Two-Column

```
┌──────────────────────────────────────────────────────────────────┐
│  ▸ EXECPROMPT                          model: qwen3:32b  ▾  [⚙]  │
├────────────────┬─────────────────────────────────────────────────┤
│                │                                                │
│  ▸ CONVOS      │              CHAT AREA                         │
│  ┌────────────┐│                                                │
│  │ 🔍 Search  ││    ┌──────────────────────────────┐            │
│  └────────────┘│    │ [USR] 14:32                  │            │
│                │    │ Tell me about quantum         │            │
│  ▸ TODAY       │    │ computing                     │            │
│    ┌──────────┐│    └──────────────────────────────┘            │
│    │ Quantum  ││                                                │
│    │ Physics ◄││    ┌──────────────────────────────┐            │
│    └──────────┘│    │ [SYS] 14:32                  │            │
│    ┌──────────┐│    │ Quantum computing leverages   │            │
│    │ API Desi ││    │ quantum mechanics...           │            │
│    │ gn Revi  ││    │                                │            │
│    └──────────┘│    │ ```python               [CP]  │            │
│                │    │ def quantum_state():           │            │
│  ▸ YESTERDAY   │    │     return superposition()     │            │
│    ┌──────────┐│    │ ```                            │            │
│    │ Rust Bo..││    │                                │            │
│    └──────────┘│    │            [CP] [ED] [RT] [RM] │            │
│                │    └──────────────────────────────┘            │
│  ─────────────││─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
│  [+] New Chat  │    ┌──────────────────────────────────────┐    │
│  [⚙] Settings  │    │ > _                    [📎] [SEND]  │    │
│  [◉] Models    │    └──────────────────────────────────────┘    │
└────────────────┴─────────────────────────────────────────────────┘
```

### Layout: DESKTOP (>1200dp) — The 13" Three-Column Experience

At 1500dp (OnePlus Pad 3 landscape), we have room for a **three-column layout** — adding a context/detail panel on the right. This is where the extra real estate truly shines.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ▸ EXECPROMPT                                   model: qwen3:32b  ▾     [⚙]  │
├──────────────┬──────────────────────────────────────────┬───────────────────┤
│              │                                          │                   │
│  SIDEBAR     │            CHAT AREA                     │   DETAIL PANEL    │
│  (280dp)     │            (max 720dp)                   │   (320dp)         │
│              │                                          │                   │
│  ▸ CONVOS    │   ┌──────────────────────────────┐       │  ▸ MODEL INFO     │
│  🔍 Search   │   │ [USR] Tell me about...       │       │  qwen3:32b        │
│              │   └──────────────────────────────┘       │  Params: 32B      │
│  ▸ Today     │                                          │  Quant: Q4_K_M    │
│    Quantum ◄ │   ┌──────────────────────────────┐       │  Context: 32K     │
│    API Des.. │   │ [SYS] Quantum computing...   │       │                   │
│  ▸ Yesterday │   │                              │       │  ▸ CONV STATS     │
│    Rust Bo.. │   │ ```python                    │       │  Messages: 24     │
│              │   │ def quantum_state():          │       │  Tokens: 12,847   │
│              │   │     return superposition()    │       │  Duration: 4m32s  │
│              │   │ ```                          │       │                   │
│              │   │                              │       │  ▸ PARAMETERS     │
│              │   │         [CP] [ED] [RT] [RM]  │       │  Temp: 0.7        │
│              │   └──────────────────────────────┘       │  Top-K: 40        │
│              │                                          │  Top-P: 0.9       │
│              │                                          │  Repeat: 1.1      │
│              │                                          │                   │
│  [+] New Chat│   ┌──────────────────────────────────┐   │  ▸ THINKING       │
│  [⚙] Setting │   │ > _                    [📎][SEND]│   │  ┌─────────────┐  │
│  [◉] Models  │   └──────────────────────────────────┘   │  │ Live stream  │  │
│              │                                          │  │ of thinking  │  │
│              │                                          │  │ content...   │  │
│              │                                          │  └─────────────┘  │
├──────────────┴──────────────────────────────────────────┴───────────────────┤
│  ▸ ExecPrompt v1.0.0-rc1               P1 Green  ▸ Connected to ollama.local │
└──────────────────────────────────────────────────────────────────────────────┘
```

### What the Detail Panel Enables (13" Only)

The right-side detail panel is **the killer feature for power users on large tablets**. It surfaces information that currently requires navigating away from the chat:

| Panel Section | Source | Phone Equivalent |
|---------------|--------|------------------|
| **Model Info** | Current model metadata from Ollama API (`/api/show`) | Only model name shown in header |
| **Conversation Stats** | Message count, token usage, conversation duration | Buried in Settings > Data Management |
| **Active Parameters** | Temperature, Top-K, Top-P, Repeat Penalty | Only in Settings screen |
| **Live Thinking** | Separate scrollable view of reasoning stream | Collapsed accordion inside message bubble |
| **Attached Images** | Full-size preview of images in conversation | Tiny 120x120 thumbnails |

**The thinking panel is particularly powerful:** On a phone, thinking content is collapsed by default because it takes too much vertical space. On a 13" tablet, we can stream thinking content into its own dedicated panel in real-time — the user sees reasoning happening on the right while the final response appears in the center. This is a **unique UX that no other Ollama client offers.**

### Font & Spacing Adjustments by Tier

| Element | Phone (< 600dp) | Tablet-S (600-840dp) | Tablet-L/Desktop (> 840dp) |
|---------|-----------------|----------------------|----------------------------|
| Body text | 13sp | 14sp | 15sp |
| Code blocks | 12sp | 13sp | 14sp |
| Message labels [USR]/[SYS] | 10sp | 11sp | 12sp |
| Action buttons [CP]/[RM] | 10sp | 11sp | 12sp |
| Chat input | 14sp | 15sp | 16sp |
| Sidebar titles | N/A | N/A | 13sp |
| Sidebar items | N/A | N/A | 12sp |
| Message bubble padding | 12dp | 14dp | 16dp |
| Message max width | 100% | 85% | 720dp fixed |
| Content horizontal padding | 8dp | 16dp | 24dp |

### Keyboard & Input Optimization (Tablet)

Tablets often have physical/Bluetooth keyboards. The tablet layout should support:

- **Enter to Send** (with Shift+Enter for newline) — currently only the SEND button works
- **Ctrl+N** → New Chat
- **Ctrl+K** → Focus search in sidebar
- **Escape** → Cancel streaming (same as STOP button)
- **Ctrl+,** → Open Settings
- These are additive — they don't affect touch-only phone usage

### Orientation Handling

| Orientation | OnePlus Pad 3 Logical Size | Layout |
|-------------|---------------------------|--------|
| Landscape | ~1500 x 1060 dp | DESKTOP tier — full 3-column layout |
| Portrait | ~1060 x 1500 dp | TABLET-L tier — 2-column (sidebar + chat) |

The layout adapts based on **width only** — orientation changes trigger a natural width-based breakpoint shift with zero special handling.

### Transition Animations (Tablet)

When switching between conversations in the sidebar, the chat area should use a subtle crossfade rather than a full-screen navigation push:

- **Phone:** Full-screen navigation with standard slide transition (current, unchanged)
- **Tablet:** In-place content swap with 150ms fade — the sidebar highlight moves, the chat area morphs. No full-screen navigation.

### What We Do NOT Change for Tablet

To protect the mobile experience, these remain untouched:

- The CyberTerm theme system — same colors, same phosphor aesthetic
- The core widget library — `MessageBubble`, `ChatInput`, `BlinkingCursor`, `CodeBlockBuilder` — content-level widgets work at any size
- The data layer — database, providers, API service — completely size-agnostic
- The overlay drawer on phone — stays exactly as-is below 840dp
- Navigation structure — GoRouter paths remain the same; only the visual shell changes

### Implementation Approach

```dart
// adaptive_shell.dart — the ONLY new structural widget needed
class AdaptiveShell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      // PHONE: Return current layout unchanged
      return const PhoneChatScreen();  // existing chat_screen.dart
    } else if (width < 1200) {
      // TABLET-L: Sidebar + Chat
      return Row(
        children: [
          SizedBox(width: 280, child: ConversationPanel()),
          Expanded(child: ChatArea()),
        ],
      );
    } else {
      // DESKTOP (13"): Sidebar + Chat + Detail
      return Row(
        children: [
          SizedBox(width: 280, child: ConversationPanel()),
          Expanded(child: ChatArea(maxWidth: 720)),
          SizedBox(width: 320, child: DetailPanel()),
        ],
      );
    }
  }
}
```

The existing `ConversationDrawer` widget is repurposed as `ConversationPanel` — same internal content, rendered inline instead of as an overlay `Drawer`. The existing `ChatScreen` body becomes `ChatArea`. The `DetailPanel` is the only fully new widget.

### Revised Effort Estimate for RC-1B

```
RC-1B (Tablet Layout — ~8 hours total)
 ├─ AdaptiveShell breakpoint wrapper              [1 hr]
 ├─ ConversationPanel (refactor from Drawer)      [1.5 hr]
 ├─ ChatArea with maxWidth + responsive spacing   [1 hr]
 ├─ DetailPanel (model info + stats + thinking)   [2.5 hr]  ← 13" feature
 ├─ Font scaling system by breakpoint             [0.5 hr]
 ├─ Keyboard shortcuts (Enter, Ctrl+N, Esc)       [1 hr]
 └─ Testing across breakpoints                    [0.5 hr]
```

---

## RC-1 Implementation Order

```
RC-1A (Polish + Critical Fixes — ~3.5 hours total)
 ├─ Issue 6: STOP generation pipeline fix          [1.5 hr]  CRITICAL ⚠️
 ├─ Issue 2: Remove "Built with Flutter"           [5 min]   TRIVIAL
 ├─ Issue 5: Delete confirmation dialog             [20 min]  SMALL
 ├─ Issue 1: Models screen fresh-install UX         [30 min]  SMALL  
 ├─ Issue 3: Image picker loading + permissions     [20 min]  SMALL
 └─ Issue 4: Image flicker fix (base64 caching)     [45 min]  MEDIUM

RC-1B (Tablet Layout — ~8 hours total, can defer to v1.1)
 ├─ AdaptiveShell breakpoint wrapper                [1 hr]
 ├─ ConversationPanel (refactor from Drawer)        [1.5 hr]
 ├─ ChatArea with maxWidth + responsive spacing     [1 hr]
 ├─ DetailPanel (model info + stats + thinking)     [2.5 hr]  ← 13" feature
 ├─ Font scaling system by breakpoint               [0.5 hr]
 ├─ Keyboard shortcuts (Enter, Ctrl+N, Esc)         [1 hr]
 └─ Testing across breakpoints                      [0.5 hr]
```

---

## Final Verdict

| Question | Answer |
|----------|--------|
| Are RC-1A fixes feasible? | ✅ YES — all 6 issues are feasible. Issue 6 (STOP) is the most critical and complex but uses well-documented Dio patterns |
| Can tablet layout coexist in same codebase? | ✅ YES — Flutter's adaptive layout is designed for exactly this |
| Same APK or separate APK? | **SAME APK** — single listing, single codebase, zero duplication |
| Play Store: one app or two? | **ONE APP** — serves phones, tablets, and foldables |
| Risk to mobile experience? | **ZERO** — all tablet code is behind width breakpoints; phone path is untouched |
| Should tablet ship in RC-1? | **OPTIONAL** — RC-1A is the priority. RC-1B can ship with RC-1 or defer to v1.1 |
| Most critical issue? | **Issue 6 (STOP)** — ship-blocking. 5 compounding bugs in the cancel pipeline |
| 13" tablet — worth it? | ✅ YES — the detail panel with live thinking stream is a unique differentiator no other Ollama client has |

---

*Document: rc_devplan.md — ExecPrompt Release Candidate Plan*  
*No code changes included. Implementation pending approval.*
