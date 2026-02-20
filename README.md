# EXECPROMPT

**AI LLM Client for Cyberpunks.**
Terminal aesthetic. Local-first. Zero telemetry.

[![BUILD](https://img.shields.io/static/v1?label=BUILD&message=PASSING&color=33FF33&labelColor=0A0F0A&style=flat-square)](https://github.com/dayofgeek/execprompt/actions)
[![LICENSE](https://img.shields.io/static/v1?label=LICENSE&message=GPL%20v3&color=33FF33&labelColor=0A0F0A&style=flat-square)](https://www.gnu.org/licenses/gpl-3.0)
[![FLUTTER](https://img.shields.io/static/v1?label=FLUTTER&message=3.x&color=E0E0E0&labelColor=0A0F0A&style=flat-square)](https://flutter.dev)
[![DART](https://img.shields.io/static/v1?label=DART&message=3.x&color=E0E0E0&labelColor=0A0F0A&style=flat-square)](https://dart.dev)

---

## [SYS] STATUS

```
CLASSIFICATION: OPEN SOURCE
VERSION:        1.0.0
ARCHITECTURE:   LOCAL-FIRST
STATUS:         OPERATIONAL
```

---

## [FEATURES]

### [PROVIDERS] Multi-LLM Support

```
[>] OpenAI          — GPT-4, GPT-3.5, o-series
[>] Anthropic       — Claude 3 + extended thinking
[>] Ollama          — Self-hosted, zero cloud dependency
[>] Custom          — Any OpenAI-compatible endpoint
```

### [CHAT] Conversation Engine

```
[>] Real-time streaming output
[>] Local history with persistence
[>] System prompts / personas
[>] Conversation threading
[>] Export: Markdown, JSON, Text
[>] Search within conversations
```

### [THEMES] 5 Terminal Aesthetics

```
AMBER   — Classic phosphor CRT
GREEN   — Vintage VT100
MATRIX  — Dark green cyberpunk
BLADE   — Blue neon futuristic
MONO    — Clean monochrome
```

### [SECURITY] Data Protection

```
[>] Encrypted API key storage (Keychain/Keystore)
[>] HTTPS-only connections
[>] Zero telemetry / zero tracking
[>] Local-first architecture
```

### [HARDWARE] Mobile-Optimized

```
[>] Native 60/120fps rendering
[>] Phone + tablet adaptive layouts
[>] Material 3 with CyberTerm aesthetic
[>] Offline mode with message queue
```

---

## [EXEC] REQUIREMENTS

```
FLUTTER SDK    >= 3.0.0
ANDROID SDK    API 21+
GIT            2.x
```

---

## [INSTALL] BUILD PROCEDURE

### Clone

```bash
git clone https://github.com/dayofgeek/execprompt.git
cd execprompt
```

### Setup

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

---

## [CONFIG] API SETUP

### OpenAI

```
ENDPOINT:   https://api.openai.com/v1
API KEY:    sk-...
MODELS:     gpt-4, gpt-4-turbo, gpt-3.5-turbo, o1, o3
```

### Anthropic Claude

```
ENDPOINT:   https://api.anthropic.com/v1
API KEY:    sk-ant-...
MODELS:     claude-3-opus, claude-3-sonnet, claude-3-haiku
```

### Ollama (Local)

```
ENDPOINT:   http://localhost:11434
            (Android emulator: http://10.0.2.2:11434)
API KEY:    (optional for local inference)
MODELS:     llama3.2, deepseek-r1, mistral, phi-4, qwen
```

---

## [ARCH] SYSTEM DESIGN

```
+-------------------------------------------------------------+
|                    PRESENTATION LAYER                        |
|         (Screens, Widgets, UI Logic — Riverpod)             |
+-------------------------------------------------------------+
|                      DOMAIN LAYER                            |
|    (Business Logic, Use Cases, State Management)            |
+-------------------------------------------------------------+
|                       DATA LAYER                             |
|  (API Services, Models, Repositories, Local Storage)        |
+-------------------------------------------------------------+
```

### Tech Stack

```
FRAMEWORK:        Flutter 3.x (Dart)
STATE:            Riverpod 2.x
HTTP:             Dio (streaming)
DATABASE:         Drift (SQLite)
SECURE STORAGE:   flutter_secure_storage
CODE GEN:         freezed, json_serializable
```

---

## [SECURITY] CLASSIFICATION

```
SECURITY GRADE:     A
CRITICAL VULNS:     0
DATA COLLECTION:    NONE
CLOUD SYNC:         DISABLED
CREDENTIAL STORAGE: PLATFORM SECURE (Keychain/Keystore)
```

### Security Model

- **Encrypted storage** — API keys in Android Keystore / iOS Keychain
- **Local-only** — Your conversations never leave your device
- **HTTPS enforcement** — All API traffic encrypted
- **Zero telemetry** — No tracking, no analytics, no data collection

Vulnerability reports: [SECURITY.md](SECURITY.md)

---

## [SCREENS] INTERFACE

| CHAT | MODELS | SETTINGS | THEMES |
|:----:|:------:|:--------:|:------:|
| [Coming] | [Coming] | [Coming] | [Coming] |

| HISTORY | EXPORT | PERSONAS | SEARCH |
|:------:|:------:|:--------:|:------:|
| [Coming] | [Coming] | [Coming] | [Coming] |

---

## [ROADMAP] DEVELOPMENT QUEUE

```
[DONE] Multi-provider LLM support
[DONE] Local chat history with persistence
[DONE] Cyberpunk terminal themes
[DONE] Secure API key storage
[TODO] iOS support
[TODO] Desktop (Linux, Windows, macOS)
[TODO] Voice input/output
[TODO] Tool calling (function calling)
[TODO] Model fine-tuning UI
[TODO] Encrypted device sync
```

---

## [CONTRIBUTE] PROTOCOL

1. Fork the repository
2. Create feature branch (`git checkout -b feature/call-sign`)
3. Write code + tests
4. Run `flutter test && flutter analyze`
5. Commit (`git commit -m 'Add call-sign feature'`)
6. Push (`git push origin feature/call-sign`)
7. Open Pull Request

See: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## [DOCS] DOCUMENTATION

```
QUICKSTART.md     — Get running in 5 minutes
CONTRIBUTING.md   — Contribution guidelines
SECURITY.md       — Security policy
CHANGELOG.md      — Version history
```

---

## [LICENSE] LEGAL

```
ExecPrompt - AI LLM Mobile Client
Copyright (C) 2026 DayOfGeek.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License v3.0
```

File: [LICENSE](LICENSE)

---

## [CREDITS]

```
FRAMEWORK:      Flutter Team
LOCAL LLM:      Ollama
API PROVIDERS:  OpenAI, Anthropic
DESIGN SYSTEM:  DayOfGeek CyberTerm
```

---

<div align="center">

**[DAYOFGEEK.COM](https://dayofgeek.com)**

</div>