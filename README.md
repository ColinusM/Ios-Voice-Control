# iOS Voice Control App

Enterprise-grade iOS application featuring real-time speech-to-text capabilities with professional audio mixer control integration. Built with SwiftUI and designed for iPhone X+ (iOS 16+) with Firebase backend services.

## 🎯 Features

- 🔐 **Enterprise Google Sign-In** with Firebase Auth integration
- 🎙️ **Real-time Speech Recognition** via AssemblyAI streaming API
- 🎛️ **Yamaha RCP Mixer Control** integration (preparation stage)
- 📱 **Native iOS SwiftUI Interface** with MVVM architecture
- 🔄 **Hot Reloading** for rapid development cycles
- 👤 **Multi-Modal Authentication** (Google, Firebase, Biometric, Guest)

## 🚀 Quick Start

**New to this project?** Follow these guides in order:

1. **[QUICKSTART.md](QUICKSTART.md)** - Get running in 15 minutes
2. **[ONBOARDING.md](ONBOARDING.md)** - Comprehensive developer guide

### Prerequisites

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** with Command Line Tools
- **iPhone 16 iOS 18.5 Simulator** (critical requirement)

### Essential Commands

```bash
# Build and run (bookmark this)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Launch app
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Debug logs (when needed)
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30
```

## 🏗️ Tech Stack

### Frontend
- **Swift 5.9+** with SwiftUI
- **MVVM Architecture** with dependency injection
- **Hot Reloading** via HotSwiftUI 1.2.1

### Authentication
- **Firebase iOS SDK 11.15.0** (Auth, Database, Firestore, Functions)
- **Google Sign-In 9.0.0** with OAuth 2.0 + PKCE
- **Biometric Authentication** (Face ID/Touch ID)
- **Guest Mode** for Apple App Store compliance

### Speech Processing
- **AssemblyAI Streaming API** for real-time transcription
- **AVAudioEngine** for audio capture
- **Starscream WebSocket 4.0.8** for real-time communication

### Development Tools
- **Xcode 15.0+** for iOS development
- **iPhone 16 iOS 18.5 Simulator** (mandatory)
- **Firebase Console** for backend management
- **Google Cloud Console** for OAuth configuration

## 📱 Project Structure

```
VoiceControlApp/
├── VoiceControlAppApp.swift          # App entry point with Firebase setup
├── ContentView.swift                 # Root view with auth flow routing
├── VoiceControlMainView.swift        # Main app interface post-auth
├── Info.plist                        # App configuration & permissions
├── GoogleService-Info.plist          # Firebase configuration
│
├── Authentication/                   # Complete authentication system
│   ├── Services/                    # Google, Firebase, Biometric services
│   ├── ViewModels/                  # Auth logic & state management
│   ├── Views/                       # Auth screens (Sign In, Sign Up, etc.)
│   └── Models/                      # Auth models & error handling
│
├── SpeechRecognition/               # Speech-to-text system
│   ├── AssemblyAIStreamer.swift     # Real-time streaming client
│   ├── AudioManager.swift           # Audio capture & processing
│   └── Models/                      # Speech processing models
│
├── Subscriptions/                   # In-app subscription system
└── Shared/                          # Common utilities & components
```

## ⚠️ Critical Requirements

### Simulator Usage (Non-Negotiable)
- **MUST use iPhone 16 iOS 18.5 simulator** (Device ID: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`)
- **NEVER use physical device or other simulators** (causes FBSceneErrorDomain crashes)
- This requirement is project-specific for Firebase compatibility

### Build Commands
- **Use `xcodebuild`** commands (not `ios-deploy`)
- **Buffer-based logging only** (5-second timeout)
- **Follow MVVM architecture** patterns consistently

## 🔧 Configuration

### Required Configuration Files
- **`GoogleService-Info.plist`**: Firebase configuration with OAuth client IDs
- **`Info.plist`**: App permissions and URL schemes
- **`VoiceControlApp.entitlements`**: iOS app capabilities

### External Services
- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
- **Firebase Console**: https://console.firebase.google.com/project/project-1020288809254/authentication
- **AssemblyAI**: Real-time streaming API for speech recognition

### Bundle Configuration
- **Bundle ID**: `com.voicecontrol.app`
- **URL Scheme**: `com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv`
- **Firebase Project**: `project-1020288809254`

## 🎨 Architecture

### MVVM Pattern
- **Models**: Data structures and business entities
- **Views**: SwiftUI views with clean UI/UX
- **ViewModels**: `@ObservableObject` coordinators with `@Published` state
- **Services**: External API integrations and system interfaces

### Key Components
- **`AuthenticationManager`**: Central auth coordinator
- **`AssemblyAIStreamer`**: Speech processing coordinator
- **`GoogleSignInService`**: OAuth 2.0 integration
- **`FirebaseAuthService`**: Firebase Auth wrapper
- **`AudioManager`**: Real-time audio capture

## 🚨 Common Gotchas

1. **Device ID Mismatch**: Always use `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
2. **Google Sign-In Bypassed**: Expected behavior in simulator (not a bug)
3. **Hot Reloading Limits**: Works for UI changes only, not architecture changes
4. **Manual GUI Actions**: Stop and request user confirmation for external configurations

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)**: 15-minute setup guide
- **[ONBOARDING.md](ONBOARDING.md)**: Comprehensive developer guide (120+ sections)
- **[CLAUDE.md](CLAUDE.md)**: Project-specific AI development guidelines
- **[docs/](docs/)**: Technical documentation for APIs and integrations
- **[PRPs/](PRPs/)**: AI-assisted development methodology and templates

## 🔗 Key Files

**Entry Points:**
- [`VoiceControlAppApp.swift`](VoiceControlApp/VoiceControlAppApp.swift) - App initialization
- [`ContentView.swift`](VoiceControlApp/ContentView.swift) - Root navigation
- [`AuthenticationManager.swift`](VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift) - Auth coordinator
- [`AssemblyAIStreamer.swift`](VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift) - Speech processing

**Configuration:**
- [`Info.plist`](VoiceControlApp/Info.plist) - App configuration
- [`GoogleService-Info.plist`](VoiceControlApp/GoogleService-Info.plist) - Firebase config
- [`Package.resolved`](VoiceControlApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved) - Dependencies

## 🚀 Getting Started Checklist

- [ ] **macOS 13.0+** with Xcode 15.0+ installed
- [ ] **iPhone 16 iOS 18.5 Simulator** configured
- [ ] **Repository cloned** and Xcode project opened
- [ ] **Build command executed** successfully
- [ ] **App launches** on required simulator
- [ ] **Read [ONBOARDING.md](ONBOARDING.md)** for comprehensive guide

---

**Ready to develop?** Start with [QUICKSTART.md](QUICKSTART.md) for immediate setup, then dive into [ONBOARDING.md](ONBOARDING.md) for complete understanding of the architecture and development workflow.