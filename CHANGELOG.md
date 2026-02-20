# Changelog

All notable changes to ExecPrompt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Work in progress features

## [1.0.0] - 2026-02-19

### Added
- Initial open source release
- Multi-provider LLM support (OpenAI, Anthropic Claude, Ollama, custom endpoints)
- Real-time streaming chat responses
- Local chat history persistence with Drift/SQLite
- System prompts and persona management
- 5 cyberpunk terminal themes (Amber, Green, Matrix, Blade, Mono)
- Secure API key storage using platform secure storage (Android Keystore / iOS Keychain)
- Conversation threading and management
- Export conversations (Markdown, JSON, Text formats)
- Search within conversations
- Model management for Ollama (browse, pull, delete)
- Material 3 design with CyberTerm aesthetic
- Offline mode with queued messages
- Adaptive layouts for phones and tablets
- Native Android performance (60/120fps animations)
- Clean Architecture implementation with Riverpod state management
- Freezed models for type-safe data classes
- Comprehensive error handling

### Security
- Encrypted local storage for chat history
- HTTPS-only API connections
- No telemetry, analytics, or data collection
- No third-party tracking services

### Technical
- Flutter 3.x with Dart 3
- Riverpod 2.x for state management
- Dio for HTTP with streaming support
- Drift for SQLite database
- flutter_secure_storage for secure API key storage
- freezed + json_serializable for code generation

---

## Release Notes Template

### [Version] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes to existing functionality

#### Deprecated
- Soon-to-be removed features

#### Removed
- Now removed features

#### Fixed
- Bug fixes

#### Security
- Security improvements
