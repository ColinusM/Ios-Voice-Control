# iOS Voice Control App - Comprehensive Developer Onboarding

Welcome to the iOS Voice Control App! This guide will get you from zero to productive contributor in one comprehensive walkthrough.

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Repository Structure](#-repository-structure)
3. [Getting Started](#-getting-started)
4. [Key Components](#-key-components)
5. [Development Workflow](#-development-workflow)
6. [Architecture Decisions](#-architecture-decisions)
7. [Common Tasks](#-common-tasks)
8. [Potential Gotchas](#-potential-gotchas)
9. [Documentation and Resources](#-documentation-and-resources)
10. [Next Steps Checklist](#-next-steps-checklist)

## 🎯 Project Overview

### Purpose and Functionality
The **iOS Voice Control App** is an enterprise-grade mobile application featuring real-time speech-to-text capabilities with professional audio mixer control integration. Built for iPhone X+ (iOS 16+), it combines secure Google OAuth authentication with AssemblyAI's streaming speech recognition.

### Core Features
- 🔐 **Enterprise Google Sign-In** with Firebase Auth integration
- 🎙️ **Real-time Speech Recognition** via AssemblyAI streaming API
- 🎛️ **Yamaha RCP Mixer Control** integration (preparation stage)
- 📱 **Native iOS SwiftUI Interface** with MVVM architecture
- 🔄 **Hot Reloading** for rapid development cycles
- 👤 **Multi-Modal Authentication** (Google, Firebase, Biometric, Guest)

### Tech Stack Summary
- **Frontend**: Swift 5.9+, SwiftUI, MVVM Architecture
- **Authentication**: Firebase iOS SDK 11.15.0, Google Sign-In 9.0.0, Biometric (Face ID/Touch ID)
- **Speech Processing**: AssemblyAI streaming API, AVAudioEngine
- **Networking**: Starscream WebSocket 4.0.8, URLSession
- **Development**: HotSwiftUI 1.2.1, Xcode 15.0+
- **Backend Services**: Firebase (Auth, Database, Firestore, Functions)

### Architecture Pattern
**MVVM (Model-View-ViewModel)** with dependency injection:
- **Models**: Data structures and business entities
- **Views**: SwiftUI views with clean UI/UX
- **ViewModels**: `@ObservableObject` coordinators with `@Published` state
- **Services**: External API integrations and system interfaces

## 📁 Repository Structure

```
PRPs-agentic-eng/                           # Root directory
├── VoiceControlApp/                         # Main iOS application
│   ├── VoiceControlAppApp.swift             # App entry point with Firebase setup
│   ├── ContentView.swift                   # Root view with auth flow routing
│   ├── VoiceControlMainView.swift           # Main app interface post-auth
│   ├── Info.plist                          # App configuration & permissions
│   ├── GoogleService-Info.plist             # Firebase configuration
│   ├── VoiceControlApp.entitlements         # iOS app capabilities
│   │
│   ├── Authentication/                      # Complete authentication system
│   │   ├── Components/                      # UI components (GoogleSignInButton)
│   │   ├── Models/                          # AuthenticationState, User, Errors
│   │   ├── Services/                        # Google, Firebase, Biometric services
│   │   ├── ViewModels/                      # AuthenticationManager, BiometricAuthManager
│   │   └── Views/                           # Auth screens (Sign In, Sign Up, etc.)
│   │
│   ├── SpeechRecognition/                   # Speech-to-text system
│   │   ├── AssemblyAIStreamer.swift         # Real-time streaming client
│   │   ├── AudioManager.swift               # Audio capture & processing
│   │   └── Models/                          # Speech processing models & config
│   │
│   ├── Subscriptions/                       # In-app subscription system
│   │   ├── Models/                          # Subscription plans & state
│   │   ├── Services/                        # StoreKit integration
│   │   ├── ViewModels/                      # Subscription management
│   │   └── Views/                           # Subscription UI components
│   │
│   └── Shared/                              # Common utilities & components
│       ├── Components/                      # Reusable UI (LoadingButton, etc.)
│       ├── Extensions/                      # Swift extensions (Color, View)
│       └── Utils/                           # Helper utilities & constants
│
├── VoiceControlApp.xcodeproj/               # Xcode project configuration
├── docs/                                    # Technical documentation
│   ├── assemblyai/                          # AssemblyAI API documentation
│   ├── yamaha-rcp/                          # Yamaha mixer control docs
│   └── apple-app-store-review-guidelines.md
│
├── PRPs/                                    # Product Requirement Prompts methodology
│   ├── templates/                           # PRP templates for AI development
│   ├── ai_docs/                             # Claude Code documentation
│   ├── scripts/                             # PRP automation scripts
│   └── Personal/                            # Project-specific PRPs
│
├── ComputerReceiver/                        # Python server for computer control
├── claude_md_files/                         # Technology-specific AI agents
├── CLAUDE.md                                # Project-specific AI guidelines
├── QUICKSTART.md                            # 15-minute setup guide
├── ONBOARDING.md                            # This comprehensive guide
└── README.md                                # Project overview & PRP methodology
```

### Key Directory Purposes

- **`VoiceControlApp/`**: Core iOS application with modular architecture
- **`Authentication/`**: Complete multi-modal auth system (Google, Firebase, Biometric)
- **`SpeechRecognition/`**: Real-time speech processing with AssemblyAI
- **`Subscriptions/`**: In-app purchase and subscription management
- **`Shared/`**: Reusable components and utilities across the app
- **`docs/`**: Technical documentation for APIs and integrations
- **`PRPs/`**: AI-assisted development methodology and templates

## 🚀 Getting Started

### Prerequisites
- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** with Command Line Tools
- **iPhone 16 iOS 18.5 Simulator** (critical - see gotchas below)
- **AssemblyAI API Key** (for speech recognition features)

### Essential Setup (15 minutes)

#### 1. Environment Setup
```bash
# Install Command Line Tools (if not already installed)
xcode-select --install

# Clone repository
git clone [repository-url]
cd PRPs-agentic-eng
```

#### 2. Simulator Configuration ⚠️ CRITICAL
You **MUST** use the iPhone 16 iOS 18.5 simulator:
- **Device ID**: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
- Open Xcode → Window → Devices and Simulators
- Ensure iPhone 16 simulator with iOS 18.5 is available
- **Never use physical device or other simulators** (causes compatibility issues)

#### 3. Project Configuration
```bash
# Open Xcode project
open VoiceControlApp.xcodeproj

# Verify Swift Package Dependencies resolve automatically:
# - Firebase iOS SDK 11.15.0
# - Google Sign-In 9.0.0
# - Starscream 4.0.8
# - HotSwiftUI 1.2.1
```

#### 4. Build and Run
```bash
# MANDATORY build command (bookmark this)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Then launch app on simulator
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app
```

### First Run Verification
After successful build, you should see:
- ✅ App launches on iPhone 16 iOS 18.5 simulator
- ✅ Authentication screen with Google Sign-In button
- ✅ No critical console errors
- ✅ UI responds to touch interactions
- ✅ Google Sign-In bypassed in simulator (expected behavior)

## 🔧 Key Components

### Application Entry Points

#### 1. VoiceControlAppApp.swift:12
**Main app entry point** with `@main` attribute:
- Configures Firebase with `FirebaseApp.configure()`
- Sets up Google OAuth URL handling for redirect flows
- Initializes the root `ContentView()`

#### 2. ContentView.swift:1
**State-based navigation router** managing authentication flow:
```swift
// Flow: AuthState → View Selection
switch authManager.authState {
    case .unauthenticated: WelcomeView()
    case .authenticating: AuthenticationView()
    case .authenticated, .guest: VoiceControlMainView()
    case .requiresBiometric: AuthenticationView()
    case .error: AuthenticationView()
}
```

#### 3. VoiceControlMainView.swift
**Main application interface** post-authentication with speech controls and user management.

### Authentication System Architecture

#### Three-Layer Authentication Pattern

**Layer 1: State Management**
- **`AuthenticationManager.swift`**: Central `@ObservableObject` coordinator
  - Manages `@Published` authentication state transitions
  - Coordinates Firebase Auth listener with UI updates
  - Handles session persistence via Keychain and UserDefaults

**Layer 2: Service Abstraction**
- **`GoogleSignInService.swift`**: Enterprise OAuth 2.0 + PKCE implementation
  - External user agent (SFSafariViewController) for security
  - Simulator detection with graceful degradation
  - Google OAuth client integration with Firebase Auth
- **`FirebaseAuthService.swift`**: Firebase Auth service wrapper
  - Modern async/await API patterns
  - CRUD operations: sign-in, sign-up, password reset, profile management
  - ID token management and validation
- **`BiometricService.swift`**: Face ID/Touch ID authentication wrapper
  - LocalAuthentication framework integration
  - Simulator-aware biometric handling

**Layer 3: Model Layer**
- **`AuthenticationState.swift`**: Type-safe state enum with 6 states
- **`User.swift`**: User data model with Firebase integration
- **`AuthenticationError.swift`**: Comprehensive error handling

#### Authentication Features
- **Multi-Modal Auth**: Email/password, Google OAuth, Guest mode, Biometric
- **Session Management**: Keychain-based secure token persistence
- **Apple Compliance**: Guest mode for App Store guidelines
- **Development Features**: Auto-login for simulator testing

### Speech Recognition Implementation

#### Real-Time Streaming Architecture

**`AssemblyAIStreamer.swift`**: WebSocket-based streaming coordinator
- **State Management**: `@ObservableObject` with published properties:
  - `isStreaming`, `transcriptionText`, `connectionState`, `errorMessage`
- **WebSocket Integration**: Starscream-based real-time connection
  - AssemblyAI v3 API with query parameter configuration
  - Automatic reconnection with exponential backoff
  - Binary audio data streaming in 50ms chunks

**`AudioManager.swift`**: Core audio capture engine
- **AVAudioEngine Integration**: Real-time PCM audio capture
- **Format Conversion Pipeline**: Float32 → Int16 PCM conversion
  - Hardware format detection (44.1kHz/48kHz → 16kHz downsampling)
  - Dynamic sample rate conversion with quality preservation
- **Permission Management**: iOS 17+ and legacy API support

#### Speech Processing Pipeline
```
Microphone → AVAudioEngine → AudioManager → Format Conversion →
AssemblyAIStreamer → WebSocket → AssemblyAI API → Real-time Transcription
```

### MVVM Implementation

#### Dependency Injection Pattern
```swift
ContentView()
└── @StateObject authManager = AuthenticationManager()
    └── VoiceControlMainView()
        ├── @EnvironmentObject authManager
        ├── @StateObject assemblyAIStreamer = AssemblyAIStreamer()
        └── @EnvironmentObject subscriptionManager
```

#### Service Architecture
```
AuthenticationManager (Central Coordinator)
├── FirebaseAuthService (Firebase operations)
├── GoogleSignInService (OAuth operations)
├── KeychainService (Secure storage)
└── BiometricService (Face ID/Touch ID)

AssemblyAIStreamer (Speech Coordinator)
├── AudioManager (Audio capture)
├── StreamingConfig (Configuration)
└── WebSocket (Starscream - Real-time communication)
```

## ⚡ Development Workflow

### Critical Workflow Requirements

#### 1. Mandatory Simulator Usage ⚠️
- **ONLY use iPhone 16 iOS 18.5 simulator** (Device ID: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`)
- **Never use physical device or other simulators** - causes FBSceneErrorDomain crashes
- This requirement is non-negotiable and project-specific

#### 2. Build Commands
```bash
# Primary build command (use this always)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Launch after successful build
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app
```

#### 3. Log Monitoring Protocol
**Buffer-based logs ONLY** (never live stream, 5-second timeout):
```bash
# Standard app logs
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30

# OAuth/authentication debugging
tail -300 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# App crashes and errors
tail -100 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

### Standard Development Cycle
1. **Make changes** to Swift files in Xcode
2. **Build and deploy** using xcodebuild command to iPhone 16 iOS 18.5 simulator
3. **Test manually** on required simulator
4. **Capture logs** when needed using buffer-based commands
5. **Iterate** quickly with hot reloading for UI changes

### Architecture Guidelines
- **MVVM Pattern**: Strict separation of Views, ViewModels, and Services
- **Dependency Injection**: Services injected into ViewModels via `@EnvironmentObject`
- **State Management**: `@Published` properties with `ObservableObject`
- **Error Handling**: `Result` types with custom error models
- **Security**: Never log sensitive data (tokens, passwords, PII)

## 🏗️ Architecture Decisions

### Why MVVM with SwiftUI?
- **Testability**: ViewModels can be unit tested independently
- **Reusability**: Services can be shared across ViewModels
- **State Management**: Clear data flow with `@Published` properties
- **SwiftUI Integration**: Natural fit with `@ObservableObject` pattern

### Authentication Architecture Choices

#### Multi-Service Integration
- **Firebase Auth**: Primary authentication provider with robust user management
- **Google Sign-In**: Enterprise OAuth 2.0 integration for corporate users
- **Biometric Auth**: Face ID/Touch ID for secure local authentication
- **Guest Mode**: Apple App Store compliance for trial users

#### Security Decisions
- **External User Agent**: OAuth flows use `SFSafariViewController` (not `WKWebView`)
- **Keychain Storage**: Secure token persistence with proper access groups
- **PKCE Implementation**: OAuth 2.0 with Proof Key for Code Exchange
- **Simulator Bypassing**: Google Sign-In bypassed in development for testing

### Speech Recognition Architecture

#### Real-Time Streaming Choice
- **AssemblyAI WebSocket**: Low-latency real-time transcription
- **AVAudioEngine**: High-quality audio capture with format conversion
- **50ms Chunks**: Balance between responsiveness and network efficiency
- **Automatic Reconnection**: Robust error handling with exponential backoff

### Development Environment Decisions

#### Hot Reloading Setup
- **HotSwiftUI 1.2.1**: Rapid UI development cycles
- **Simulator-Only Development**: Consistent testing environment
- **Buffer-Based Logging**: Efficient debugging without performance impact

## 🛠️ Common Tasks

### Adding New Authentication Method

1. **Create service** in `Authentication/Services/`:
```swift
class NewAuthService: ObservableObject {
    func authenticate(credentials: Credentials) async -> Result<User, AuthenticationError> {
        // Implementation
    }
}
```

2. **Extend authentication state** in `AuthenticationState.swift`:
```swift
enum AuthenticationMethod: CaseIterable {
    case google, firebase, biometric, newMethod
}
```

3. **Update AuthenticationManager**:
```swift
@Published var newAuthService = NewAuthService()

func authenticateWithNewMethod() async {
    // Integration logic
}
```

4. **Add UI components** in `Authentication/Views/`:
```swift
struct NewAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    // View implementation
}
```

### Adding New Speech Recognition Feature

1. **Extend models** in `SpeechRecognition/Models/`:
```swift
struct NewSpeechFeature: Codable {
    let featureType: String
    let parameters: [String: Any]
}
```

2. **Modify AssemblyAIStreamer**:
```swift
func handleNewFeature(_ data: Data) {
    // Feature processing logic
    DispatchQueue.main.async {
        self.newFeatureResult = processedResult
    }
}
```

3. **Update StreamingConfig**:
```swift
struct StreamingConfig {
    var newFeatureEnabled: Bool = false
    var newFeatureParameters: [String: Any] = [:]
}
```

### Debugging Common Issues

#### Build Failures
- Clean Xcode build folder: **⌘⇧K**
- Verify iPhone 16 iOS 18.5 simulator is running
- Check Device ID matches exactly: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
- Ensure Swift Package dependencies resolved

#### Authentication Issues
- Check URL schemes in `Info.plist`: `com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv`
- Verify `GoogleService-Info.plist` present and configured
- Google Sign-In bypassed in simulator is expected behavior
- Check Firebase project configuration

#### Speech Recognition Issues
- Verify microphone permissions granted
- Check AssemblyAI API key configuration
- Test WebSocket connectivity
- Monitor audio format conversion pipeline

### Project Configuration Tasks

#### Environment Variables and API Keys
```swift
// In Constants.swift
struct APIKeys {
    static let assemblyAI = "your-assemblyai-key"
    static let firebaseProject = "project-1020288809254"
}
```

#### Info.plist Configuration
Required permissions and URL schemes:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for real-time speech recognition.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition to process voice commands and transcribe audio.</string>

<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv</string>
</array>
```

## ⚠️ Potential Gotchas

### Critical Configuration Dependencies

#### 1. Version Discrepancies ⚠️
- **CLAUDE.md Device ID**: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
- **QUICKSTART.md Device ID**: `734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8`
- **Resolution**: Use CLAUDE.md Device ID (authoritative source)

#### 2. Google OAuth Configuration
- **Bundle ID**: Must be exactly `com.voicecontrol.app`
- **URL Scheme**: `com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv`
- **Gotcha**: Google Sign-In bypassed in simulator (by design, not a bug)
- **Firebase Project**: `project-1020288809254`

#### 3. Build Command Confusion
- **QUICKSTART.md shows**: `ios-deploy` commands (outdated)  
- **CLAUDE.md requires**: `xcodebuild` commands (correct)
- **Resolution**: Always use `xcodebuild` commands from CLAUDE.md

#### 4. Simulator Requirement
- **Must use**: iPhone 16 iOS 18.5 simulator only
- **Never use**: Physical device or other simulators
- **Why**: Prevents FBSceneErrorDomain crashes and Firebase compatibility issues

### Development Workflow Gotchas

#### 1. Log Monitoring Rules
- **Buffer-based only**: Never use live streaming commands
- **5-second timeout**: All log commands must complete within 5 seconds
- **Specific commands**: Use provided log commands, don't improvise

#### 2. Authentication Flow Complexities
- **Multiple services**: Google, Firebase, Biometric services can cause race conditions
- **State synchronization**: Auth state changes must be coordinated
- **Session persistence**: Keychain and UserDefaults must stay synchronized

#### 3. Hot Reloading Limitations
- **UI changes only**: Hot reloading works for UI modifications
- **Architecture changes**: Require full rebuild
- **State preservation**: May lose app state during hot reload

### Security and Compliance Gotchas

#### 1. Never Log Sensitive Data
```swift
// ❌ Wrong
print("User token: \(userToken)")

// ✅ Correct  
print("User authentication successful")
```

#### 2. External Service Dependencies
- **Google Cloud Console**: Manual configuration required
- **Firebase Console**: Manual project setup required
- **AssemblyAI API**: API key management required

#### 3. App Store Compliance
- **Guest mode**: Required for Apple App Store approval
- **Permission descriptions**: Must be accurate and specific
- **OAuth flows**: Must use external user agent (not in-app WebView)

### Manual Action Stop Rule ⚠️

When **ANY** task requires manual GUI actions:

1. **STOP implementation immediately**
2. **Identify specific manual action needed**
3. **Provide direct URLs**:
   - Google Cloud Console: `https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254`
   - Firebase Console: `https://console.firebase.google.com/project/project-1020288809254/authentication`
4. **Give step-by-step instructions**
5. **Wait for user confirmation before proceeding**

## 📚 Documentation and Resources

### Project Documentation

#### Core Documentation
- **`CLAUDE.md`**: Project-specific AI development guidelines and mandatory rules
- **`QUICKSTART.md`**: 15-minute setup guide (but use CLAUDE.md for build commands)
- **`README.md`**: PRP methodology and project overview
- **This file (`ONBOARDING.md`)**: Comprehensive developer guide

#### Technical Documentation (`/docs/`)
- **`docs/assemblyai/`**: AssemblyAI API reference and implementation guides
  - `streaming-api.md`: WebSocket API documentation
  - `streaming-guide.md`: Integration best practices
  - `python-example.md`: Reference implementation
- **`docs/yamaha-rcp/`**: Yamaha mixer control documentation (future feature)
- **`docs/apple-app-store-review-guidelines.md`**: App Store compliance guide

#### AI Development Resources (`/PRPs/`)
- **`PRPs/templates/`**: Structured prompt templates for AI-assisted development
- **`PRPs/ai_docs/`**: Claude Code documentation and best practices
- **`PRPs/scripts/`**: Automation scripts for PRP execution
- **`PRPs/Personal/`**: Project-specific Product Requirement Prompts

### External Service Documentation

#### Google Services
- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
- **OAuth 2.0 Documentation**: https://developers.google.com/identity/protocols/oauth2
- **Google Sign-In iOS Documentation**: https://developers.google.com/identity/sign-in/ios

#### Firebase Services  
- **Firebase Console**: https://console.firebase.google.com/project/project-1020288809254/overview
- **Firebase Auth Documentation**: https://firebase.google.com/docs/auth/ios/start
- **Firebase iOS SDK**: https://github.com/firebase/firebase-ios-sdk

#### AssemblyAI Services
- **AssemblyAI Documentation**: https://www.assemblyai.com/docs/
- **Real-time Streaming API**: https://www.assemblyai.com/docs/walkthroughs#realtime-streaming-transcription
- **WebSocket API Reference**: https://www.assemblyai.com/docs/api/realtime

### Technology-Specific Agents (`/claude_md_files/`)
Specialized AI agents for different technologies:
- **`CLAUDE-SWIFT-IOS-AGENT.md`**: Swift/iOS development best practices
- **`CLAUDE-REACT.md`**: React development patterns (for web components)
- **`CLAUDE-NODE.md`**: Node.js server patterns (for backend services)
- **`CLAUDE-PYTHON-BASIC.md`**: Python development (for automation scripts)

### API References and Keys

#### Configuration Files
- **`GoogleService-Info.plist`**: Firebase configuration with OAuth client IDs
- **`Info.plist`**: App configuration, permissions, and URL schemes
- **`VoiceControlApp.entitlements`**: iOS app capabilities and security settings

#### Key Dependencies (Package.resolved)
- **Firebase iOS SDK**: 11.15.0
- **Google Sign-In**: 9.0.0
- **Starscream WebSocket**: 4.0.8
- **HotSwiftUI**: 1.2.1
- **AppAuth-iOS**: 2.0.0

## ✅ Next Steps Checklist

### 1. Environment Setup
- [ ] **macOS 13.0+** with Xcode 15.0+ installed
- [ ] **Command Line Tools** installed (`xcode-select --install`)
- [ ] **iPhone 16 iOS 18.5 Simulator** configured (Device ID: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`)
- [ ] **Repository cloned** and Xcode project opened

### 2. First Build Success
- [ ] **Swift Package Dependencies** resolved automatically
- [ ] **Build command executed** successfully:
  ```bash
  cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build
  ```
- [ ] **App launches** on iPhone 16 iOS 18.5 simulator
- [ ] **Authentication screen** appears correctly
- [ ] **No critical console errors** during startup

### 3. Understanding Core Architecture
- [ ] **Read key files**:
  - [ ] `VoiceControlAppApp.swift` (app entry point)
  - [ ] `ContentView.swift` (navigation router)
  - [ ] `Authentication/ViewModels/AuthenticationManager.swift` (auth coordinator)
  - [ ] `SpeechRecognition/AssemblyAIStreamer.swift` (speech processing)
- [ ] **Understand MVVM pattern** and dependency injection
- [ ] **Grasp authentication flow** (Google, Firebase, Biometric, Guest)

### 4. First Development Task
- [ ] **Make a small UI change** (e.g., button text modification)
- [ ] **Rebuild and test** using standard workflow
- [ ] **Verify hot reloading** works for UI changes
- [ ] **Test authentication flow** (note: Google Sign-In bypassed in simulator)

### 5. Testing and Debugging
- [ ] **Grant microphone permissions** when prompted
- [ ] **Test speech recognition** functionality
- [ ] **Practice log capture** using buffer-based commands
- [ ] **Understand error handling** patterns in the codebase

### 6. Development Workflow Mastery
- [ ] **Bookmark build command** for quick access
- [ ] **Set up log monitoring aliases** for efficient debugging
- [ ] **Practice common tasks** (adding UI components, modifying ViewModels)
- [ ] **Understand manual action stop rule** for GUI configuration tasks

### 7. Advanced Understanding
- [ ] **Explore PRP methodology** in `/PRPs/` directory
- [ ] **Review technology agents** in `/claude_md_files/`
- [ ] **Study external API integrations** (Google, Firebase, AssemblyAI)
- [ ] **Understand subscription system** architecture

### 8. Contributing to Project
- [ ] **Follow MVVM architecture** patterns consistently
- [ ] **Use existing code conventions** and naming patterns
- [ ] **Implement proper error handling** with Result types
- [ ] **Add appropriate logging** (without sensitive data)
- [ ] **Test on required simulator** before code submission

### 9. Documentation and Learning
- [ ] **Review comprehensive documentation** in `/docs/` directory
- [ ] **Understand AssemblyAI integration** for speech features
- [ ] **Study Yamaha RCP preparation** for future mixer control
- [ ] **Explore AI-assisted development** with PRP templates

### 10. Ready for Production Work
- [ ] **Can build and run** app consistently
- [ ] **Understand authentication system** architecture
- [ ] **Can modify speech recognition** features
- [ ] **Know debugging workflow** and log analysis
- [ ] **Familiar with common gotchas** and how to avoid them
- [ ] **Ready to contribute** following project conventions

---

## 🎉 You're Ready to Develop!

Congratulations! You now have a comprehensive understanding of the iOS Voice Control App architecture, development workflow, and best practices. You're equipped to:

- Build and deploy the app consistently
- Navigate the codebase efficiently
- Implement new features following MVVM patterns
- Debug issues using proper log analysis
- Avoid common gotchas and development pitfalls
- Contribute effectively to the project

### Quick Reference Commands

```bash
# Build and run (bookmark this)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Standard debugging logs
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30
```

### Key Reminders
- **Always use iPhone 16 iOS 18.5 simulator** (Device ID: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`)
- **Follow MVVM architecture** with dependency injection
- **Use buffer-based logging** only (5-second timeout)
- **Stop for manual GUI actions** and request user confirmation

Happy coding! 🚀