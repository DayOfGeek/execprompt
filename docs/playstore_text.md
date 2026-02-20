# ExecPrompt - Play Store Listing

## Short Description (80 characters max)
Multi-provider AI. Function over friction. Built for power users.

## Full Description (4000 characters max)

ExecPrompt is a multi-provider AI chat client built for people who prefer function over friction. Connect to local Ollama, Ollama Cloud, OpenRouter, Anthropic, or OpenAI. All from one interface. No accounts required. Your keys, your control.

**Multi-Provider Architecture**

Connect to Ollama running on your device or homelab. Add OpenRouter for access to Claude, GPT, Gemini, and hundreds of other models. Use Anthropic or OpenAI APIs directly. Switch between providers and models without changing tools. The app adapts to what you connect.

**Full-Text Search**

Search across conversation titles and message content. Results show matching snippets. Works across all conversations regardless of provider.

**Export Conversations**

Export individual conversations as JSON or Markdown. Share via any app. Your data, your format. No lock-in.

**Token Usage Tracking**

See input, output, and total tokens for each conversation. Supported on OpenRouter, OpenAI, Anthropic, and Ollama endpoints that report usage. In-memory only, resets on app restart.

**Reasoning Model Support**

Models that output thinking traces (DeepSeek R1, Claude with extended thinking, Gemini Thinking) display their reasoning in a dedicated section. Collapsible, copy-pasteable, never in the way.

**Conversation Management**

Create, rename, delete, search, and export conversations. Fork a conversation to explore different paths. All stored locally in SQLite. No cloud sync, no telemetry.

**Custom Parameters**

Temperature, top-p, top-k, max tokens, presence penalty, frequency penalty. Set them or leave defaults. Toggle parameter sending per-request to work around provider quirks.

**Web Search Integration**

Enable web search for grounded responses. Supports Tavily and Ollama (when using Ollama Cloud). Bring your own API keys. Results include source citations.

**Ollama Cloud Access**

Direct support for Ollama Cloud models. Configure your Ollama Cloud endpoint alongside local Ollama servers, OpenRouter, Anthropic, and OpenAI. Unified interface across all providers.

**Privacy First**

Your API keys stay on your device. Encrypted in flutter_secure_storage. No analytics, no crash reporting, no telemetry. The app talks to your configured endpoints and nothing else.

**Terminal Aesthetic**

No gradients, no rounded corners, no animations for the sake of animations. Monospace everywhere. CyberTerm color palette (green, amber, blue, pink). For those who know.

**Platform Support**

Currently available for Android. iOS version under consideration for future release.

**Who This Is For**

Power users who run Ollama locally. Developers switching between Claude, GPT, and local models. People who want export, search, and token tracking without subscriptions. Anyone tired of apps that treat settings like trade secrets.

**What This Isn't**

Not a beginner-friendly chat interface. Not optimized for casual use. No hand-holding, no tutorials, no gamification. If you need to ask what Ollama is, this probably isn't your app.

**Technical Details**

- Flutter-based native Android app
- SQLite for local conversation storage
- Drift ORM with migration support
- Riverpod state management
- SSE streaming for real-time responses
- Code block syntax highlighting
- LaTeX math rendering
- Tool calling support (web search)
- Multi-modal input (image + text) where supported

**Requirements**

- Android 6.0 or higher
- Internet connection for cloud providers
- API keys for OpenRouter, Anthropic, or OpenAI (if using)
- Ollama instance (local or remote) for local models

**Support**

No customer service. No phone support. Contact via website only. Use at your own risk. Built by one person between consulting gigs. Updates when I have time.

Built by DayOfGeek. Unapologetically geek.

---

## What's New (Release Notes Template)

### Version 1.0.0 - Initial Release

First public release. Multi-provider support, conversation search, export, token tracking, and reasoning model display.

Core features:
- Ollama (local and Cloud), OpenRouter, Anthropic, OpenAI support
- Full-text conversation search
- JSON and Markdown export
- Token usage display
- Thinking/reasoning trace rendering
- Web search with Tavily and Ollama
- Custom parameter control
- Fork conversations
- Local-only storage

No known critical bugs. Tested on Pixel 7 and Samsung Galaxy Tab S8. Your hardware may vary.

---

## Category

Productivity

## Content Rating

Everyone

## Tags / Keywords

ollama, ai chat, openrouter, anthropic, claude, gpt, local llm, privacy, terminal, power user, offline ai, api client, multi-provider, developer tools

---

## Support URL

https://dayofgeek.com/exec/prompt/

## Privacy Policy URL

https://dayofgeek.com/privacy.txt
