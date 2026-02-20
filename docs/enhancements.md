# ExecPrompt Enhancement Plan

**Generated:** 2026-02-11  
**Goal:** Feature parity with ChatGPT/Claude mobile + unique retro UI identity  
**Current State:** Basic chat working, database foundation in place, no conversation management

---

## Section 1: Feature Parity Analysis

### What ChatGPT Mobile Has (that we need)

#### 1.1 Conversation Management (CRITICAL - We have nothing)
- **Conversation sidebar/drawer** — Swipe or tap to open history panel
- **Conversation list** — Sorted by recency, grouped by "Today / Yesterday / Previous 7 Days / Older"
- **New chat button** — Prominent "+" to start fresh conversation
- **Conversation titles** — Auto-generated from first message, editable
- **Search conversations** — Full-text search across all history
- **Delete conversations** — Individual deletion with confirmation
- **Archive conversations** — Hide without deleting
- **Rename conversations** — Tap to edit title inline
- **Pin conversations** — Keep important ones at top

#### 1.2 Chat Experience (Gaps)
- **Markdown rendering** — ✅ We have this (flutter_markdown)
- **Code blocks with syntax highlighting** — ⚠️ Partial (no syntax highlighting)
- **Copy code blocks** — ❌ Missing (can copy full message but not individual blocks)
- **Streaming responses** — ✅ Working
- **Stop generation** — ✅ Working
- **Regenerate response** — ⚠️ Partial (retry exists but not proper regenerate)
- **Edit & resend user message** — ❌ Missing
- **Branch conversations** — ❌ Missing (edit creates new branch in ChatGPT)
- **Message actions (copy, share, like/dislike)** — ⚠️ Partial (copy only)
- **Share conversation** — ❌ Missing
- **Haptic feedback** — ❌ Missing
- **Swipe to reply** — ❌ Missing (not applicable for us)

#### 1.3 Model Management
- **Model selector in chat** — ❌ Must leave chat to change model (poor UX)
- **Model info display** — ⚠️ Basic (size only, no capabilities shown)
- **Quick model switching** — ❌ Missing dropdown/picker in chat header

#### 1.4 Settings & Personalization
- **System prompt / Custom instructions** — ✅ Working
- **Theme selection** — ❌ Only system light/dark
- **Data export** — ❌ Missing
- **Clear all data** — ❌ Missing
- **Notification preferences** — N/A (not cloud-based)
- **Default model selection** — ✅ Working

#### 1.5 UI/UX Polish
- **Empty state with suggestions** — ❌ Missing (just "Start a conversation")
- **Prompt suggestions/starters** — ❌ Missing
- **Loading skeletons** — ❌ Using basic spinner
- **Pull-to-refresh** — ❌ Not applicable for chat
- **Scroll-to-bottom FAB** — ❌ Missing (auto-scroll only)
- **Keyboard handling** — ⚠️ Basic
- **Long-press context menus** — ❌ Missing
- **Animations & transitions** — ⚠️ Basic slide transitions only

### What Claude Mobile Has (additional)
- **Thinking display** — ✅ We have this now
- **Artifacts / Canvas** — ❌ Missing (complex, lower priority)
- **Projects** — ❌ Missing (conversation grouping)
- **Starred messages** — ❌ Missing
- **Conversation export** — ❌ Missing

---

## Section 2: Retro UI Design Concept

### 2.1 Design Philosophy: "CyberTerm"

Forget flat modern Material Design. ExecPrompt should feel like a **cyberpunk terminal interface** — a UI that looks like it was pulled from a hacker's workstation in a William Gibson novel, but is actually a smooth, modern touch interface.

**Key Principles:**
- **Monospace typography** as primary font — everything feels like a terminal
- **Scanline/CRT effects** subtle but present — phosphor glow, slight text bloom
- **High contrast** — bright text on deep dark backgrounds
- **Minimal chrome** — no heavy Material cards, use borders and ASCII-inspired dividers
- **Status bar aesthetic** — information-dense headers like a terminal status line
- **Cursor blink** — blinking cursor on streaming responses instead of spinner

### 2.2 Theme System: "Phosphor Palettes"

Each theme is named after a classic CRT phosphor color:

#### Theme: **P1 Green** (Palm Pilot / Matrix)
```
Background:     #0a0f0a (near-black green-tinted)
Surface:        #0f1a0f (slightly lighter)
Primary:        #33ff33 (classic green phosphor)
Primary Dim:    #1a8a1a (muted green)
Text:           #33ff33 (green on dark)
Text Dim:       #1a6b1a (faded green)
Accent:         #66ff66 (bright highlight)
Error:          #ff3333 (red alarm)
Border:         #1a3a1a (subtle green border)
User Bubble:    #1a2f1a (dark green)
Bot Bubble:     #0f1a0f (near background)
```

#### Theme: **P3 Amber** (Classic Terminal)
```
Background:     #0f0a00 (near-black amber-tinted)
Surface:        #1a1200 (slightly lighter)
Primary:        #ffb300 (amber phosphor)
Primary Dim:    #8a6200 (muted amber)
Text:           #ffb300 (amber on dark)
Text Dim:       #8a7a33 (faded amber)
Accent:         #ffd54f (bright amber)
Error:          #ff5252 (red alarm)
Border:         #3a2a00 (subtle amber border)
User Bubble:    #2a1f00 (dark amber)
Bot Bubble:     #1a1200 (near background)
```

#### Theme: **P4 White** (Classic Bright Terminal)
```
Background:     #0a0a0f (near-black cool)
Surface:        #12121a (slightly lighter)
Primary:        #e0e0ff (cool white phosphor)
Primary Dim:    #7a7a8a (muted white)
Text:           #e0e0ff (white on dark)
Text Dim:       #7a7a9a (faded)
Accent:         #ffffff (pure bright)
Error:          #ff4444 (red alarm)
Border:         #2a2a3a (subtle border)
User Bubble:    #1a1a2a (dark blue-grey)
Bot Bubble:     #12121a (near background)
```

#### Theme: **Neon Cyan** (Cyberpunk)
```
Background:     #050a0f (deep dark blue)
Surface:        #0a1520 (slightly lighter)
Primary:        #00ffff (cyan neon)
Primary Dim:    #007a7a (muted cyan)
Text:           #00ffff (cyan on dark)
Text Dim:       #337a7a (faded cyan)
Accent:         #ff00ff (magenta accent)
Error:          #ff3366 (hot pink error)
Border:         #0a2a3a (subtle cyan border)
User Bubble:    #0a1f2a (dark cyan)
Bot Bubble:     #0a1520 (near background)
```

#### Theme: **Synthwave** (Purple/Pink 80s)
```
Background:     #0f0a1a (deep purple-black)
Surface:        #1a1030 (slightly lighter)
Primary:        #ff66ff (hot pink/magenta)
Primary Dim:    #8a3a8a (muted)
Text:           #e0b0ff (lavender text)
Text Dim:       #8a6aaa (faded lavender)
Accent:         #00ffff (cyan contrast)
Error:          #ff3333 (red)
Border:         #2a1a3a (purple border)
User Bubble:    #2a1040 (dark purple)
Bot Bubble:     #1a1030 (near background)
```

### 2.3 UI Component Design Language

#### Terminal-Style App Bar
```
┌──────────────────────────────────────┐
│ ☰  ExecPrompt v1.0 │ qwen3:8b │ ● │
│    ─────────────────────────────     │
└──────────────────────────────────────┘
```
- Monospace font throughout
- Model name in header like a status indicator  
- Green/amber dot for connection status
- Hamburger (☰) opens conversation drawer

#### Terminal-Style Message Bubbles
- No rounded corners — use sharp rectangles with 1px borders
- ASCII-art style role indicators: `[USR]>` and `[BOT]>`
- Timestamp as terminal-style: `[14:32:07]`
- Scanline overlay on bot messages (subtle)

#### Terminal-Style Input
```
┌──────────────────────────────────┐
│ > █                              │
│                         [↵] [◉] │
└──────────────────────────────────┘
```
- Blinking cursor prompt `> █`
- Minimal border, no rounded pill shape
- Send button as `[↵]` or terminal return symbol
- Image attach as `[◉]`

#### Conversation Drawer
```
┌─────────────────────┐
│ ▸ CONVERSATIONS     │
│ ─────────────────── │
│ + New Chat           │
│ ─────────────────── │
│ TODAY                │
│  > Square root of... │
│  > Code review fo... │
│ YESTERDAY            │
│  > Explain quantu... │
│  > Write a poem a... │
│ OLDER                │
│  > Setup guide fo... │
│ ─────────────────── │
│ ⚙ Settings           │
│ 📊 Models             │
└─────────────────────┘
```

#### Streaming Indicator
Instead of a spinner, use a blinking block cursor: `█` that pulses with a phosphor glow effect. When thinking mode is active, show: `[THINKING...]█`

### 2.4 Typography

- **Primary font:** `JetBrains Mono`, `Fira Code`, or `Source Code Pro` (monospace)
- **Markdown rendered text:** Same monospace, but with bold/italic support
- **Headers in markdown:** Larger weight, with `═══` underline decoration
- **Code blocks:** Slightly different background shade, with `┌──┐` border

### 2.5 Animations & Effects

- **Message appear:** Typewriter effect option (characters appear one by one) or instant
- **Theme change:** Smooth cross-fade between phosphor colors
- **Drawer open:** Slide from left with terminal boot-up feel
- **Loading:** Pulsing phosphor glow instead of circular spinner
- **Cursor blink:** 530ms interval, classic block cursor
- **Button press:** Brief flash/highlight in primary color

---

## Section 3: Priority Implementation Order

### Phase 1: Conversation Management (CRITICAL)
**Effort:** ~8 hours | **Impact:** Without this the app is not usable for daily use

1. Wire up existing Drift database to chat provider
2. Build conversation drawer with history list
3. Auto-save conversations (create on first message, update on each reply)
4. New chat functionality
5. Conversation title auto-generation (first ~40 chars of user message)
6. Delete conversation
7. Rename conversation
8. Search conversations

### Phase 2: Retro Theme System (~6 hours)
**Effort:** ~6 hours | **Impact:** Unique brand identity

1. Create theme data classes with all 5 phosphor palettes
2. Add monospace font (Google Fonts or bundled)
3. Theme provider with persistence
4. Theme selector in settings
5. Apply theme to all screens

### Phase 3: UI Overhaul — Terminal Aesthetic (~8 hours)
**Effort:** ~8 hours | **Impact:** Complete visual transformation

1. Redesign message bubbles (sharp corners, borders, role tags)
2. Redesign chat input (terminal prompt style)
3. Redesign app bar (status line style)
4. Streaming cursor (blinking block instead of spinner)
5. Conversation drawer styling
6. Settings screen cleanup and redesign
7. Empty state with retro prompt suggestions

### Phase 4: Chat Experience Polish (~4 hours)
**Effort:** ~4 hours | **Impact:** Catch-up with competitor UX

1. Model selector dropdown in chat header
2. Code block syntax highlighting (flutter_highlight or similar)
3. Copy individual code blocks
4. Edit & resend user messages
5. Scroll-to-bottom FAB
6. Haptic feedback on actions

### Phase 5: Settings Overhaul (~3 hours)
**Effort:** ~3 hours | **Impact:** Clean up wasted space, add missing features

1. Consolidate settings into logical sections
2. Add theme picker (visual preview)
3. Add data management (export chats as JSON/Markdown, clear all data)
4. Add about section with version, build info
5. Connection test with detailed diagnostics
6. Quick actions (clear cache, reset preferences)

---

## Total Estimated Effort: ~29 hours
## Priority: Phase 1 > Phase 2 > Phase 3 > Phase 4 > Phase 5
