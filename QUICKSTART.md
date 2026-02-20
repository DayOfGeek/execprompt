# Quick Start Guide - ExecPrompt

Get ExecPrompt up and running in 5 minutes!

## Prerequisites Checklist
- [ ] Flutter SDK installed (3.0.0+) - [Get Flutter](https://flutter.dev/docs/get-started/install)
- [ ] Android Studio or VS Code with Flutter extensions
- [ ] Ollama server running (local or cloud access)

## Setup Steps

### 1. Install Flutter (if not already installed)

**macOS/Linux:**
```bash
# Download Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

**Windows:**
Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)

### 2. Clone and Setup ExecPrompt

```bash
# Clone repository
git clone https://github.com/zervin/dayofgeek.git
cd execprompt

# Install dependencies
flutter pub get

# Generate required code (Freezed models)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Setup Ollama Server

Choose one option:

#### Option A: Local Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama (runs on http://localhost:11434)
ollama serve

# Pull a model
ollama pull llama3.2
```

#### Option B: Ollama Cloud
1. Sign up at [cloud.ollama.com](https://cloud.ollama.com)
2. Get your API key from the dashboard
3. Use URL: `https://ollama.com`

### 4. Configure Android Device/Emulator

#### For Android Emulator:
```bash
# Create an emulator (if needed)
flutter emulators --create

# Launch emulator
flutter emulators --launch <emulator_id>
```

#### For Physical Device:
1. Enable Developer Options on your Android device
2. Enable USB Debugging
3. Connect via USB
4. Verify: `flutter devices`

### 5. Run the App

```bash
flutter run
```

The app will launch on your connected device/emulator.

### 6. Configure the App

On first run:

1. **Go to Settings** (⚙️ icon)
   
2. **Enter Server URL:**
   - **Local (emulator):** `http://10.0.2.2:11434`
   - **Local (physical device):** `http://YOUR_COMPUTER_IP:11434`
   - **Cloud:** `https://ollama.com`
   
3. **Enter API Key** (if using cloud)
   
4. **Tap Save**

5. **Go to Models** (💾 icon)
   
6. **Pull a model:**
   - Tap the ➕ floating button
   - Enter model name (e.g., `llama3.2`, `deepseek-r1:7b`)
   - Wait for download to complete
   
7. **Select the model** by tapping on it

8. **Go to Chat** and start conversing!

## Common Connection URLs

| Scenario | URL |
|----------|-----|
| Local Ollama on emulator | `http://10.0.2.2:11434` |
| Local Ollama on device (same network) | `http://192.168.1.X:11434` |
| Ollama Cloud | `https://ollama.com` |
| Custom server | `http://your-server:11434` |

## Troubleshooting

### "Connection timeout" or "Network error"
✅ **Solution:**
- Check Ollama server is running: `curl http://localhost:11434/api/version`
- For emulator, use `10.0.2.2` instead of `localhost`
- For device, ensure same network and use computer's IP

### "No models installed"
✅ **Solution:**
- Pull a model using the Models screen
- Or via CLI: `ollama pull llama3.2`
- Refresh the models list

### "Build fails with Freezed errors"
✅ **Solution:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### "MissingPluginException"
✅ **Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

## Recommended Models

| Model | Size | Best For |
|-------|------|----------|
| `llama3.2:1b` | ~1.3 GB | Fast responses, basic tasks |
| `llama3.2:3b` | ~2 GB | Balanced performance |
| `deepseek-r1:7b` | ~4.7 GB | Reasoning and complex tasks |
| `qwen2.5:3b` | ~2.2 GB | Multilingual support |
| `phi3:3.8b` | ~2.3 GB | Compact, efficient |

## Development Mode

For development with hot reload:
```bash
flutter run --debug
```

For performance testing:
```bash
flutter run --profile
```

## Building Release APK

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Next Steps

- 📖 Read [README.md](README.md) for full feature list
- 🛠️ Check [DEVELOPMENT.md](docs/DEVELOPMENT.md) for coding guidelines
- 📊 Review [IMPLEMENTATION.md](docs/IMPLEMENTATION.md) for architecture details
- 🎨 Explore [Flutter Style Guide](docs/styleguide_flutter.md) for UI/UX design principles
- 🌐 Review [Web Style Guide](docs/styleguide_web.md) for web development guidelines

## Getting Help

- 🐛 Found a bug? [Open an issue](https://github.com/zervin/dayofgeek/issues)
- 💬 Have questions? [Start a discussion](https://github.com/zervin/dayofgeek/discussions)
- 📚 Need Ollama help? [Ollama Docs](https://github.com/ollama/ollama)

---

**Ready to chat!** 🚀 Enjoy using ExecPrompt with your favorite Ollama models.
