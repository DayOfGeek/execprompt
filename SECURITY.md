# Security

## Reporting Issues

Found a security issue? Email: security@dayofgeek.com

Do not open public issues for security vulnerabilities.

## Security Model

**Local-First Architecture**
- API keys stored in platform secure storage
- Android: Keystore + EncryptedSharedPreferences
- iOS: Keychain
- Never written to logs

**Network Security**
- HTTPS-only connections to LLM APIs
- No HTTP fallback
- No proxy or middleman

**Data Privacy**
- Chat history stored locally on device
- No cloud sync
- No telemetry or analytics
- Export is user-initiated only

**Code Transparency**
- GPL v3 licensed — full source available
- No closed-source components

## Responsibility

You are responsible for:
- Securing your API keys
- Verifying API endpoints
- Reviewing what data is sent to LLM providers
- Understanding provider privacy policies

ExecPrompt provides the tools. You provide the judgment.

## License

GPL v3 — See LICENSE file
