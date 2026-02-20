# Development Guide - ExecPrompt

This guide covers development setup, coding standards, and contribution guidelines for the ExecPrompt project.

---

## Prerequisites

### Required Tools
- **Flutter SDK**: 3.0.0 or higher
  - Install from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Run `flutter doctor` to verify installation
- **Dart SDK**: 3.0.0 or higher (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter/Dart extensions
- **Android SDK**: API level 21 to 34
- **Git**: For version control

### Recommended Tools
- **Android Emulator**: For testing
- **Ollama**: Local instance for development
  - Install from [ollama.com](https://ollama.com)
  - Default runs on `http://localhost:11434`

---

## Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/zervin/dayofgeek.git
cd execprompt
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code
The project uses Freezed for immutable models and JSON serialization. Generate the required files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configure Ollama Server

For **Android Emulator**, the emulator's `localhost` is different from your host machine:
- Use `http://10.0.2.2:11434` instead of `http://localhost:11434`

For **Physical Device**:
- Ensure your device and computer are on the same network
- Use your computer's IP address: `http://192.168.x.x:11434`
- Or use Ollama Cloud: `https://ollama.com` with an API key

### 5. Run the App
```bash
flutter run
```

Or select your device/emulator in your IDE and press Run.

---

## Project Structure

```
execprompt/
├── lib/
│   ├── data/                    # Data layer
│   │   ├── models/              # Data models (Freezed)
│   │   │   ├── chat_message.dart
│   │   │   ├── chat_request.dart
│   │   │   ├── chat_response.dart
│   │   │   ├── endpoint.dart         # Named endpoint (Freezed, EndpointType enum)
│   │   │   ├── model_info.dart       # Provider-agnostic model representation
│   │   │   ├── ollama_model.dart
│   │   │   └── pull_request.dart
│   │   └── services/            # API clients & adapters
│   │       ├── api_adapter.dart      # Abstract adapter contract
│   │       ├── anthropic_adapter.dart # Anthropic Messages API (SSE)
│   │       ├── ollama_adapter.dart   # Wraps OllamaApiService
│   │       ├── ollama_api_service.dart
│   │       └── openai_adapter.dart   # OpenAI-compatible (SSE)
│   ├── domain/                  # Domain layer
│   │   └── providers/           # Riverpod providers & state
│   │       ├── chat_provider.dart    # Adapter-routed chat orchestration
│   │       ├── endpoint_provider.dart # CRUD, persistence, secure storage
│   │       ├── models_provider.dart  # Multi-endpoint model aggregation
│   │       └── settings_provider.dart
│   ├── presentation/            # Presentation layer
│   │   ├── screens/             # Full screens
│   │   │   ├── adaptive_shell.dart   # Multi-layout responsive shell
│   │   │   ├── chat_screen.dart
│   │   │   ├── endpoint_config_screen.dart # Add/edit endpoint form
│   │   │   ├── models_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/             # Reusable widgets
│   │       ├── endpoint_list_section.dart  # Endpoint list for Settings
│   │       ├── model_picker.dart          # Multi-endpoint model selector
│   │       ├── message_bubble.dart
│   │       └── chat_input.dart
│   └── main.dart                # App entry point
├── android/                     # Android native code
├── test/                        # Unit & widget tests
├── integration_test/            # Integration tests
├── pubspec.yaml                 # Dependencies
├── analysis_options.yaml        # Linter rules
└── README.md                    # Project overview
```

---

## Multi-Provider Architecture

### Adding a New Provider

1. Add a new value to `EndpointType` enum in `data/models/endpoint.dart`
2. Create `data/services/your_adapter.dart` extending `ApiAdapter`
3. Register the adapter in `endpoint_provider.dart`'s `adapterForEndpointProvider` switch
4. Run `build_runner` to regenerate Freezed code

### ApiAdapter Contract

Every adapter must implement:
- `streamChat(ChatRequest)` → `Stream<ChatResponse>` — streaming chat completion
- `listModels()` → `Future<List<ModelInfo>>` — available model discovery
- `cancelActiveRequest()` — cancel in-flight request
- `buildToolResultMessage(toolName, content, toolCallId)` — provider-specific tool result format
- `testConnection()` → `Future<String>` — connection health check
- `updateBaseUrl(url)` / `updateApiKey(key)` — runtime reconfiguration

### Current Adapters

| Adapter | Protocol | Streaming | Auth |
|---|---|---|---|
| `OllamaAdapter` | Ollama native `/api/chat` | NDJSON | Optional Bearer |
| `OpenAiAdapter` | OpenAI `/v1/chat/completions` | SSE | Bearer token |
| `AnthropicAdapter` | Anthropic `/v1/messages` | SSE typed events | `x-api-key` header |

### Endpoint Flow

```
User selects model → endpointForModelProvider(model) → Endpoint
  → adapterForEndpointProvider(endpoint) → ApiAdapter
  → adapter.streamChat(request) → Stream<ChatResponse>
```

---

## Coding Standards

### Dart Style Guide
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `flutter analyze` to check for issues
- Format code with `dart format .`

### Naming Conventions
- **Classes**: PascalCase (e.g., `ChatProvider`, `OllamaApiService`)
- **Variables/Functions**: camelCase (e.g., `selectedModel`, `sendMessage`)
- **Constants**: lowerCamelCase with `const` or `final` (e.g., `defaultTimeout`)
- **Private members**: prefix with `_` (e.g., `_handleError`)

### File Organization
- One class per file
- File names in snake_case matching the main class name
- Group imports: Dart SDK → Flutter → Third-party → Relative

Example:
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message.dart';
import '../widgets/message_bubble.dart';
```

### State Management with Riverpod
- Use `StateProvider` for simple state
- Use `StateNotifierProvider` for complex state with logic
- Use `FutureProvider` for async data fetching
- Use `StreamProvider` for continuous data streams

### Freezed Models
- All data models should be immutable using Freezed
- Include `fromJson` and `toJson` for API serialization
- Use `@Default()` for optional fields with defaults

Example:
```dart
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String role,
    required String content,
    @Default([]) List<String> images,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
```

---

## Code Generation

### When to Regenerate
Run code generation after:
- Adding/modifying Freezed models
- Adding/modifying JSON serializable classes
- Adding Riverpod generator annotations

### Commands
```bash
# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs

# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Testing

### Running Tests
```bash
# All tests
flutter test

# Specific file
flutter test test/providers/chat_provider_test.dart

# With coverage
flutter test --coverage
```

### Test Structure
- **Unit tests**: `test/` directory
  - Test providers, services, utilities
- **Widget tests**: `test/widgets/` directory
  - Test individual widgets
- **Integration tests**: `integration_test/` directory
  - Test full user flows

### Writing Tests
Use the AAA pattern (Arrange, Act, Assert):
```dart
test('should add user message to chat state', () {
  // Arrange
  final container = ProviderContainer();
  final notifier = container.read(chatProvider.notifier);

  // Act
  notifier.addUserMessage('Hello');

  // Assert
  final state = container.read(chatProvider);
  expect(state.messages.length, 1);
  expect(state.messages[0].message.content, 'Hello');
});
```

---

## Building

### Development Build
```bash
flutter run --debug
```

### Profile Build (performance testing)
```bash
flutter run --profile
```

### Release Build
```bash
# APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

Built files are in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## Debugging

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Then run your app and open the DevTools URL.

### Logging
Use the `print` function sparingly. For production:
```dart
import 'dart:developer' as developer;

developer.log('Message', name: 'ExecPrompt');
```

### Common Issues

**Issue**: Build fails with "No implementation found for method"
- **Solution**: Run `flutter clean` and `flutter pub get`

**Issue**: Freezed models not generated
- **Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Issue**: Cannot connect to Ollama on emulator
- **Solution**: Use `10.0.2.2:11434` instead of `localhost:11434`

**Issue**: "MissingPluginException"
- **Solution**: Stop the app, run `flutter clean`, then rebuild

---

## Git Workflow

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code improvements
- `docs/description` - Documentation updates

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add image upload support for vision models
fix: correct NDJSON parsing for streaming responses
docs: update API endpoint documentation
refactor: simplify chat provider state management
```

### Pull Request Process
1. Create a feature branch from `main`
2. Make your changes
3. Run tests: `flutter test`
4. Run linter: `flutter analyze`
5. Format code: `dart format .`
6. Commit with descriptive messages
7. Push and create a pull request
8. Request review

---

## Adding Dependencies

### Process
1. Add to `pubspec.yaml` under appropriate section
2. Run `flutter pub get`
3. If it's a code generator, update `build_runner` command
4. Document usage in relevant files

### Categories
```yaml
dependencies:
  # Framework
  flutter:
    sdk: flutter
  
  # State management
  flutter_riverpod: ^2.4.9
  
  # Networking
  dio: ^5.4.0

dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  
  # Code generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
```

---

## Performance Tips

### Best Practices
- Use `const` constructors where possible
- Avoid rebuilding widgets unnecessarily
- Use `ListView.builder` for long lists
- Implement proper `keys` for animated lists
- Profile before optimizing: `flutter run --profile`

### Riverpod Performance
- Scope providers appropriately
- Use `select` to watch specific fields
- Avoid global state when local state suffices

---

## Resources

### Official Documentation
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Docs](https://riverpod.dev)
- [Ollama API Docs](https://github.com/ollama/ollama/blob/main/docs/api.md)

### Package Documentation
- [Dio (HTTP Client)](https://pub.dev/packages/dio)
- [Freezed (Immutable Models)](https://pub.dev/packages/freezed)
- [go_router (Navigation)](https://pub.dev/packages/go_router)
- [gpt_markdown (Rendering)](https://pub.dev/packages/gpt_markdown)

### Learning Resources
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)
- [Riverpod Examples](https://github.com/rrousselGit/riverpod/tree/master/examples)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## Getting Help

### Issues & Bugs
- Search existing issues first
- Use issue templates
- Provide minimal reproduction steps
- Include Flutter/Dart versions

### Questions
- Check documentation first
- Ask in GitHub Discussions
- Provide context and what you've tried

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

Happy coding! 🚀
