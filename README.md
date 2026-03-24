# AI Chat — Flutter Native App

A fully native Flutter chatbot app for Android & iOS, converted from the HTML chatbot.  
Direct API calls — no backend, no Puter.js dependency.

---

## Features

| Feature | Status |
|---|---|
| OpenRouter (200+ models) | ✅ |
| Anthropic API direct | ✅ |
| SSE streaming responses | ✅ |
| Stop generation | ✅ |
| Auto-detect temperature & tokens | ✅ |
| Dark / Light theme | ✅ |
| Chat history (SQLite) | ✅ |
| Auto-title conversations | ✅ |
| Edit message + regenerate | ✅ |
| Regenerate last response | ✅ |
| Image attachments (vision) | ✅ |
| File attachments (text/code) | ✅ |
| Voice input | ✅ |
| In-chat search | ✅ |
| Export / Share chat | ✅ |
| Encrypted API key storage | ✅ |
| System prompt | ✅ |
| Manual temp + token sliders | ✅ |
| Suggestion chips (empty state) | ✅ |
| Copy code / copy message | ✅ |
| Markdown rendering | ✅ |
| Syntax highlighting | ✅ |

---

## Quick Start

### Prerequisites

```bash
# Flutter SDK 3.22+ required
flutter --version

# Verify doctor
flutter doctor
```

### 1. Clone / unzip the project

```bash
cd ai_chat
flutter pub get
```

### 2. Run on Android

```bash
# Connect device or start emulator
flutter run
```

### 3. Run on iOS

```bash
# Install pods first
cd ios && pod install && cd ..
flutter run
```

---

## Getting API Keys

### OpenRouter (Free $1 credit on signup, 200+ models)
1. Go to [openrouter.ai](https://openrouter.ai)
2. Sign up → API Keys → Create key
3. Paste into the app: Settings → API Keys → OpenRouter API Key

### Anthropic (Pay-as-you-go)
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. API Keys → Create key
3. Paste into the app: Settings → API Keys → Anthropic API Key

---

## Project Structure

```
lib/
├── main.dart                         # App entry point
├── data/
│   ├── models/
│   │   ├── attachment.dart           # Image/file attachment model
│   │   ├── message.dart              # Chat message model
│   │   └── chat.dart                 # Chat session model
│   ├── db/
│   │   └── database_helper.dart      # SQLite schema
│   └── repositories/
│       ├── chat_repository.dart      # Chat + message CRUD
│       └── settings_repository.dart  # Prefs + secure storage
├── services/
│   ├── ai_service.dart               # Abstract AI interface
│   ├── openrouter_service.dart       # OpenRouter SSE impl
│   ├── anthropic_service.dart        # Anthropic SSE impl
│   └── auto_detect_service.dart      # Auto temp/token detection
├── providers/
│   └── providers.dart                # All Riverpod providers
└── ui/
    ├── theme/
    │   └── app_theme.dart            # Dark + light themes
    ├── screens/
    │   └── chat_screen.dart          # Main chat screen
    ├── drawer/
    │   └── history_drawer.dart       # Sidebar + model selector
    ├── widgets/
    │   ├── message_bubble.dart       # User + AI message bubbles
    │   ├── input_row.dart            # Input + attachments + voice
    │   ├── empty_state.dart          # Welcome screen
    │   └── streaming_cursor.dart     # Animated typing cursor
    └── sheets/
        └── settings_sheet.dart       # Settings bottom sheet
```

---

## Building for Release

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Xcode required)

```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode → Archive → Distribute
```

---

## Signing (Android)

Create a keystore:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Create `android/key.properties`:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path to upload-keystore.jks>
```

Update `android/app/build.gradle` to load `key.properties`.

---

## Adding New Models

Edit the model lists in `lib/ui/drawer/history_drawer.dart`:

```dart
const _orModels = [
  (id: 'your/model-id', label: 'My Model', vision: false),
  // ...
];
```

---

## Architecture Notes

- **State**: Riverpod `StateNotifierProvider` — reactive, testable
- **DB**: SQLite via `sqflite` — messages and chats survive app restarts
- **API keys**: `flutter_secure_storage` — stored in Android Keystore / iOS Keychain
- **Streaming**: `http.StreamedResponse` + SSE parsing — same logic as the original JS
- **Auto-detect**: Direct port of the HTML app's regex-based heuristic (lines 878–920)

---

## Tested On

- Android 12+ (API 31+)
- iOS 15+
- Flutter 3.22 (stable)

---

## License

MIT — free to use, modify, and distribute.
