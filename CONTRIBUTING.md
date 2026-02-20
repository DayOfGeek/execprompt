# Contributing to ExecPrompt

Thank you for your interest in contributing to ExecPrompt! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Security Vulnerability Reporting](#security-vulnerability-reporting)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Code of Conduct

This project and everyone participating in it is governed by our commitment to:

- **Be respectful** - Treat everyone with respect. Healthy debate is encouraged, but harassment is not tolerated.
- **Be constructive** - Provide constructive feedback and be open to receiving it.
- **Be collaborative** - Work together towards the best possible solution.
- **Be inclusive** - Welcome newcomers and help them get started.

## Security Vulnerability Reporting

**DO NOT** open a public issue for security vulnerabilities.

Instead, please email security concerns to:
**security@dayofgeek.com**

Include:
- Description of the vulnerability
- Steps to reproduce (if applicable)
- Potential impact
- Suggested fix (if any)

We will respond within 48 hours and work with you to address the issue.

---

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/execprompt.git
   cd execprompt
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/dayofgeek/execprompt.git
   ```
4. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/my-feature-name
   # or
   git checkout -b fix/issue-description
   ```

---

## Development Environment

### Prerequisites

- Flutter SDK 3.0.0+
- Dart 3.0.0+
- Android Studio or VS Code with Flutter extensions
- Android SDK (for Android development)

### Setup

```bash
# Install dependencies
flutter pub get

# Generate code (freezed models, riverpod providers, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test

# Check code analysis
flutter analyze
```

### Watch Mode (for development)

When making frequent changes to models or providers:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Pull Request Process

1. **Update your fork** before starting:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Make your changes** following our coding standards

3. **Add tests** for new functionality

4. **Update documentation** if needed (README, inline docs, etc.)

5. **Run quality checks**:
   ```bash
   flutter analyze
   flutter test
   ```

6. **Commit with clear messages** (see [Commit Messages](#commit-messages))

7. **Push to your fork**:
   ```bash
   git push origin feature/my-feature-name
   ```

8. **Open a Pull Request** against the `main` branch

### PR Requirements

- Clear description of what changed and why
- Link to related issues (e.g., "Fixes #123")
- Screenshots/GIFs for UI changes
- All CI checks must pass
- At least one code review approval

### PR Title Format

```
type(scope): description

Examples:
feat(chat): add message threading support
fix(ui): resolve theme switching bug
docs(readme): update installation instructions
test(models): add unit tests for ChatMessage
```

---

## Coding Standards

### Dart/Flutter Style

We follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and [Flutter Style Guide](https://docs.flutter.dev/development/ui/layout).

Key points:

- **Use `flutter_lints`** - Project uses `flutter_lints` package
- **Line length** - 80 characters max
- **Naming**:
  - `PascalCase` for classes, enums, typedefs
  - `camelCase` for variables, functions, parameters
  - `SCREAMING_SNAKE_CASE` for constants
- **Imports** - Organize: Dart SDK → Flutter → Third-party → Project

### Architecture Patterns

ExecPrompt follows **Clean Architecture**:

```
lib/
├── data/           # Data layer - API, database, models
│   ├── models/     # Data models (freezed)
│   └── services/   # API clients, database access
├── domain/         # Domain layer - business logic
│   └── providers/  # Riverpod state management
└── presentation/   # UI layer
    ├── screens/    # Full page screens
    └── widgets/    # Reusable widgets
```

**Rules:**
- UI (presentation) should not directly call APIs
- Use providers in domain layer for state management
- Models should be immutable (use `freezed`)
- Keep widgets small and focused

### State Management

We use **Riverpod** for state management:

```dart
// Good - Using Riverpod provider
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    // ...
  }
}

// Bad - StatefulWidget with setState for global state
class BadScreen extends StatefulWidget {
  // Don't do this for shared state
}
```

### Widget Guidelines

- **Prefer `const` constructors** when possible
- **Keep widgets small** - Split large widgets into smaller ones
- **Extract reusable widgets** - Don't duplicate UI code
- **Use `ConsumerWidget` or `ConsumerStatefulWidget`** for Riverpod

```dart
// Good
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});
  
  final ChatMessage message;
  
  @override
  Widget build(BuildContext context) {
    return Container(/* ... */);
  }
}
```

### Model Guidelines

Use `freezed` for all data models:

```dart
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required MessageRole role,
    DateTime? timestamp,
  }) = _ChatMessage;
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
```

### API Service Guidelines

```dart
// Good - Abstract class + implementation
abstract class ApiService {
  Future<ChatResponse> sendMessage(ChatRequest request);
}

class OpenAiService implements ApiService {
  // Implementation
}

// Good - Using Dio with proper error handling
class ApiClient {
  final Dio _dio;
  
  Future<T> get<T>(String path) async {
    try {
      final response = await _dio.get(path);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
```

### Error Handling

```dart
// Good - Specific error types
try {
  await apiService.sendMessage(request);
} on NetworkException catch (e) {
  // Handle network error
} on ApiException catch (e) {
  // Handle API error
} catch (e) {
  // Handle unexpected error
}

// Good - Using Result types or AsyncValue in Riverpod
final chatProvider = FutureProvider.family((ref, String id) async {
  return await repository.getChat(id);
});
```

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): subject

body (optional)

footer (optional)
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style (formatting, semicolons, etc.)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Build process, dependencies, etc.

### Examples

```
feat(chat): add conversation search functionality

Implement full-text search within chat history using SQLite FTS5.
Includes debounced search input and highlight matching.

Closes #234
```

```
fix(ui): resolve theme switching on Android 12+

Theme changes weren't applying immediately on Android 12+
due to Material 3 dynamic color. Added explicit theme rebuild.

Fixes #198
```

---

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/chat_message_test.dart
```

### Writing Tests

```dart
// Unit test
void main() {
  group('ChatMessage', () {
    test('should create from JSON', () {
      final json = {
        'id': '123',
        'content': 'Hello',
        'role': 'user',
      };
      
      final message = ChatMessage.fromJson(json);
      
      expect(message.id, '123');
      expect(message.content, 'Hello');
      expect(message.role, MessageRole.user);
    });
  });
}

// Widget test
testWidgets('MessageBubble displays text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: ChatMessage(
            id: '1',
            content: 'Hello',
            role: MessageRole.user,
          ),
        ),
      ),
    ),
  );
  
  expect(find.text('Hello'), findsOneWidget);
});
```

### Test Coverage

- All new features must include tests
- Aim for >80% coverage on new code
- Integration tests for critical user paths

---

## Documentation

### Code Documentation

Use Dart doc comments:

```dart
/// Sends a chat message to the API and returns the response.
///
/// [request] contains the message content and configuration.
/// Returns a [ChatResponse] with the AI's reply.
/// Throws [ApiException] if the request fails.
Future<ChatResponse> sendMessage(ChatRequest request) async {
  // ...
}
```

### README Updates

Update README.md if you:
- Add new features
- Change the installation process
- Modify the API

### Changelog

Significant changes should be noted in [CHANGELOG.md](CHANGELOG.md).

---

## Questions?

- Open an issue for bugs or feature requests
- Join discussions in GitHub Discussions
- Email: hello@dayofgeek.com

Thank you for contributing to ExecPrompt! 🚀
