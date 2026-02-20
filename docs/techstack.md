# Tech Stack Selection — ExecPrompt Mobile Client

## 1. Decision Context

Based on the findings in [`research.md`](./research.md), the mobile client must support:

- **Real-time NDJSON streaming** — parsing and rendering tokens as they arrive from `/api/generate` and `/api/chat`.
- **Rich Markdown rendering** — including fenced code blocks with syntax highlighting, inline/block LaTeX math, tables, and lists.
- **Multimodal input** — camera capture and gallery image selection for vision models.
- **Complex state management** — multi-turn conversation history, model management state, streaming token buffers, and pull progress tracking.
- **Butter-smooth animations** — 60/120fps scrolling, transitions, and streaming text display.
- **Play Store distribution** — must compile to a native Android APK/AAB.

---

## 2. Candidate Evaluation

### 2.1 Flutter (Dart)

| Criterion | Assessment | Score |
|-----------|-----------|:-----:|
| **Performance** | Custom Skia/Impeller rendering engine — bypasses platform views entirely. AOT-compiled Dart delivers near-native frame rates. Impeller (stable since Flutter 3.16+) eliminates shader compilation jank. | ★★★★★ |
| **Streaming Text** | Dart's `Stream` and `StreamBuilder` are first-class primitives. HTTP streaming via `dart:io` or `http` package. Efficient widget tree diffing handles rapid text appends at 60fps without dropped frames. | ★★★★★ |
| **Markdown + LaTeX** | `gpt_markdown` — purpose-built for AI/chat output with LaTeX, code highlighting, and streaming-friendly rendering. Also: `flutter_markdown` + `flutter_markdown_latex` + `flutter_math_fork` for modular approach. `markdown_widget` includes built-in code highlighting. | ★★★★★ |
| **Multimodal** | `image_picker`, `camera` packages — mature, well-maintained. Base64 encoding via `dart:convert`. | ★★★★★ |
| **State Management** | `Riverpod`, `Bloc`, or `Provider` — all production-proven. Fine-grained reactivity for streaming token buffers and model lists. | ★★★★★ |
| **Animations** | Implicit/explicit animation APIs, `AnimatedList`, `Hero`, custom `Ticker`-based animations. 60/120fps rendering loop is engine-native. | ★★★★★ |
| **Platform Integration** | Platform channels for native Android APIs. `url_launcher`, `shared_preferences`, `path_provider` — all mature. | ★★★★☆ |
| **Binary Size** | ~15-20 MB baseline for a release APK — acceptable for Play Store. | ★★★★☆ |
| **Developer Velocity** | Hot reload, strong typing (Dart), rich IDE support (VS Code, Android Studio). Single codebase for potential iOS expansion. | ★★★★★ |
| **Play Store Readiness** | First-class Android target. `flutter build appbundle` produces Play Store-ready AABs. | ★★★★★ |

**Overall: 48/50**

---

### 2.2 Kotlin / Jetpack Compose

| Criterion | Assessment | Score |
|-----------|-----------|:-----:|
| **Performance** | Truly native — runs on ART/JVM with hardware acceleration. Zero abstraction overhead. Best possible Android performance. | ★★★★★ |
| **Streaming Text** | Kotlin `Flow` and coroutines for streaming HTTP. Compose's state system (`mutableStateOf`) efficiently recomposes only changed text segments. | ★★★★★ |
| **Markdown + LaTeX** | Limited first-party options. Community libraries like `Markwon` (View-based) or custom Compose composables exist but are less mature for LaTeX. Requires integration of multiple libraries (e.g., `Markwon` + `MathJax` WebView or custom KaTeX renderer). | ★★★☆☆ |
| **Multimodal** | Native Android `CameraX`, `MediaStore` — best possible integration. | ★★★★★ |
| **State Management** | Compose state + `ViewModel` + `StateFlow` — Google's recommended architecture. Efficient recomposition scoping. | ★★★★★ |
| **Animations** | Compose animation APIs (`animate*AsState`, `AnimatedVisibility`, `Transition`). Native 60/120fps with variable refresh rate support. | ★★★★★ |
| **Platform Integration** | Full Android SDK access — no bridges or abstractions. Notifications, background services, deep links — all native. | ★★★★★ |
| **Binary Size** | ~5-10 MB for a Compose app — smallest of all options. | ★★★★★ |
| **Developer Velocity** | Compose preview, Kotlin's concise syntax. However, Android-only — no cross-platform story without Compose Multiplatform (still maturing for iOS). | ★★★★☆ |
| **Play Store Readiness** | Gold standard — Google's own framework. | ★★★★★ |

**Overall: 46/50**

---

### 2.3 React Native (TypeScript)

| Criterion | Assessment | Score |
|-----------|-----------|:-----:|
| **Performance** | Fabric renderer + JSI (JavaScript Interface) improve over old bridge. Hermes engine compiles JS ahead-of-time. However, complex streaming updates still involve JS→native boundary crossings that can cause micro-jank. | ★★★★☆ |
| **Streaming Text** | Fetch API streaming or `EventSource` polyfills. State updates via React's reconciler — batched updates help but high-frequency token appends (50+ tokens/sec) can stress the bridge. | ★★★☆☆ |
| **Markdown + LaTeX** | `react-native-markdown-display` for Markdown. LaTeX requires WebView-based `react-native-mathjax` or `KaTeX` — adds complexity and potential performance overhead. Code highlighting via `react-native-syntax-highlighter`. | ★★★☆☆ |
| **Multimodal** | `react-native-image-picker`, `react-native-camera` — functional but historically fragile across OS versions. | ★★★★☆ |
| **State Management** | Zustand, Redux Toolkit, Jotai — excellent ecosystem. React's concurrent features help with streaming. | ★★★★☆ |
| **Animations** | `react-native-reanimated` (v3) runs on UI thread — capable of 60fps. `Moti` for declarative animations. However, achieving consistent 120fps requires careful optimization. | ★★★★☆ |
| **Platform Integration** | TurboModules for native access. Large community module ecosystem but quality varies. | ★★★★☆ |
| **Binary Size** | ~20-30 MB baseline — includes Hermes runtime, native modules. | ★★★☆☆ |
| **Developer Velocity** | Fast iteration with Fast Refresh. TypeScript support. Huge JS ecosystem. Web knowledge transfers. | ★★★★★ |
| **Play Store Readiness** | Mature — many production apps (Instagram, Shopify, Discord) use RN. | ★★★★★ |

**Overall: 38/50**

---

## 3. Comparison Matrix

| Criterion                | Flutter | Kotlin/Compose | React Native |
|--------------------------|:-------:|:--------------:|:------------:|
| Raw Performance          | ★★★★★  | ★★★★★          | ★★★★☆        |
| Streaming Text Rendering | ★★★★★  | ★★★★★          | ★★★☆☆        |
| Markdown + LaTeX         | ★★★★★  | ★★★☆☆          | ★★★☆☆        |
| Multimodal (Camera/Gallery) | ★★★★★ | ★★★★★       | ★★★★☆        |
| State Management         | ★★★★★  | ★★★★★          | ★★★★☆        |
| Animation Quality        | ★★★★★  | ★★★★★          | ★★★★☆        |
| Platform Integration     | ★★★★☆  | ★★★★★          | ★★★★☆        |
| Binary Size              | ★★★★☆  | ★★★★★          | ★★★☆☆        |
| Developer Velocity       | ★★★★★  | ★★★★☆          | ★★★★★        |
| Play Store Readiness     | ★★★★★  | ★★★★★          | ★★★★★        |
| **Total**                | **48**  | **46**         | **38**       |

---

## 4. Recommendation: Flutter

### Why Flutter Wins

**Flutter is the recommended stack** for ExecPrompt based on the following decisive factors:

1. **Streaming Text is a Core UX Requirement.** Flutter's `Stream`/`StreamBuilder` primitives and widget tree diffing are architecturally ideal for real-time token rendering. The Impeller engine eliminates shader jank during rapid text appends — a common pain point in chat UIs.

2. **Markdown + LaTeX Ecosystem is Unmatched.** The `gpt_markdown` package was specifically designed for AI chatbot output rendering (used by GPT clients). It handles streaming Markdown, LaTeX math (`$...$`, `$$...$$`), and code syntax highlighting in a single widget. No other framework has an equivalent purpose-built solution.

3. **Cross-Platform Optionality.** While the initial target is Android, Flutter provides a path to iOS and desktop with the same codebase — important for future expansion without rewriting.

4. **Performance Parity with Native.** Impeller's precompiled shaders and Dart's AOT compilation deliver 60/120fps rendering that is indistinguishable from native Compose in real-world usage.

5. **Mature Ecosystem for AI Chat Apps.** Multiple production Flutter chat apps exist, with well-tested patterns for streaming, message bubbles, code rendering, and model selection UIs.

### Where Kotlin/Compose Excels

Kotlin/Compose would be the right choice if:
- The app were **Android-only with no cross-platform plans**.
- **Markdown + LaTeX rendering** were not a core requirement.
- **Minimal binary size** were a hard constraint.
- Deep integration with Android Jetpack libraries (WorkManager, Room) were critical from day one.

### Why Not React Native

React Native falls short due to:
- **Streaming performance** — the JS→native bridge introduces latency for high-frequency token updates.
- **Markdown + LaTeX** — requires combining multiple fragile libraries with WebView fallbacks.
- **Animation consistency** — achieving 120fps requires significant optimization effort.

---

## 5. Selected Tech Stack

### Core Framework

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter (stable channel) | UI framework |
| **Language** | Dart 3.x | Application language |
| **Min SDK** | Android API 21 (Android 5.0) | Platform target |
| **Build** | `flutter build appbundle` | Play Store distribution |

### State Management

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **State** | Riverpod 2.x | Reactive state management with dependency injection |
| **Async** | Dart Streams + StreamBuilder | Real-time NDJSON streaming |
| **Persistence** | Drift (SQLite) | Local conversation history and settings |

### Networking

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **HTTP Client** | Dio | HTTP with interceptors, streaming support |
| **Streaming** | Dio + StreamTransformer | NDJSON parsing for `/api/generate` and `/api/chat` |
| **Connectivity** | connectivity_plus | Network status monitoring |

### UI & Rendering

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Markdown** | gpt_markdown | AI-optimized Markdown + LaTeX + code rendering |
| **Theme** | Material 3 (Material You) | Adaptive theming with dynamic color |
| **Animations** | Flutter implicit/explicit animations | 60/120fps transitions |
| **Icons** | Material Symbols / Lucide | Iconography |

### Media & Platform

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Camera** | image_picker / camera | Photo capture for vision models |
| **Files** | file_picker | Document/image selection |
| **Storage** | shared_preferences | User settings and API keys |
| **Security** | flutter_secure_storage | Secure API key storage |

### Architecture

| Component | Pattern | Purpose |
|-----------|---------|---------|
| **Architecture** | Clean Architecture (3-layer) | Separation of concerns |
| **Data Layer** | Repository pattern | Abstract API and local data sources |
| **Presentation** | MVVM with Riverpod providers | Reactive UI binding |
| **Navigation** | go_router | Declarative routing |

---

## 6. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │  Chat UI  │  │ Model    │  │ Settings │  │  Model      │ │
│  │ (Stream)  │  │ Library  │  │   Page   │  │  Details    │ │
│  └─────┬────┘  └────┬─────┘  └────┬─────┘  └──────┬──────┘ │
│        │            │             │               │         │
│  ┌─────┴────────────┴─────────────┴───────────────┴──────┐  │
│  │               Riverpod Providers (MVVM)               │  │
│  └───────────────────────┬───────────────────────────────┘  │
├──────────────────────────┼──────────────────────────────────┤
│                    Domain Layer                              │
│  ┌───────────────────────┴───────────────────────────────┐  │
│  │           Use Cases / Business Logic                   │  │
│  │  • SendMessage  • PullModel  • ListModels             │  │
│  │  • StreamChat   • DeleteModel • GenerateEmbedding     │  │
│  └───────────────────────┬───────────────────────────────┘  │
├──────────────────────────┼──────────────────────────────────┤
│                     Data Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐    │
│  │  Ollama API  │  │  Local DB   │  │  Secure Storage  │    │
│  │  (Dio HTTP)  │  │  (Drift)    │  │  (API Keys)      │    │
│  └─────────────┘  └─────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Key Implementation Notes

### NDJSON Streaming Pattern

```dart
// Pseudocode for streaming chat tokens
Stream<ChatToken> streamChat(ChatRequest request) async* {
  final response = await dio.post(
    '/api/chat',
    data: request.toJson(),
    options: Options(responseType: ResponseType.stream),
  );

  await for (final chunk in response.data.stream) {
    final lines = utf8.decode(chunk).split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final json = jsonDecode(line);
      yield ChatToken.fromJson(json);
    }
  }
}
```

### Markdown Rendering with gpt_markdown

```dart
// Rendering streamed AI output with LaTeX and code highlighting
GptMarkdown(
  data: streamedContent,  // Accumulating string from stream
  style: GptMarkdownStyle(
    // Theme-aware styling
  ),
)
```

### Model Pull Progress UI

```dart
// Real-time pull progress tracking
StreamBuilder<PullProgress>(
  stream: ollamaRepo.pullModel('llama3.2'),
  builder: (context, snapshot) {
    final progress = snapshot.data;
    return LinearProgressIndicator(
      value: progress?.completed / progress?.total,
    );
  },
)
```
