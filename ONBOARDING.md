# iOS Voice Control App - Developer Onboarding Guide

Welcome to the iOS Voice Control App project! This comprehensive guide will help you understand the codebase, set up your development environment, and start contributing effectively.

## 1. Project Overview

### What is This Project?

The **iOS Voice Control App** is an enterprise-grade mobile application that combines real-time speech recognition with mixer control capabilities. Built with SwiftUI and designed for iPhone X+ (iOS 16+), it features secure authentication and professional audio control integration.

### Core Features

- 🔐 **Enterprise Google Sign-In** with Firebase Authentication
- 🎙️ **Real-time Speech Recognition** via AssemblyAI streaming API
- 🎛️ **Yamaha RCP Mixer Control** integration for professional audio equipment
- 📱 **Native iOS SwiftUI Interface** with MVVM architecture
- 🔄 **Hot Reloading** for rapid development cycles
- 🔒 **Biometric Authentication** (Face ID/Touch ID) support

### Tech Stack

**Frontend:**
- Swift 5.9+ with SwiftUI
- MVVM architecture pattern
- ObservableObject for state management
- HotSwiftUI for hot reloading

**Backend & Services:**
- Firebase (Auth, Database, Firestore, Functions)
- Google Sign-In SDK 9.0.0
- AssemblyAI real-time streaming API
- Starscream WebSocket library for real-time communication

**Development Tools:**
- Xcode 15.0+
- ios-deploy for simulator deployment
- iOS Simulator (specifically iPhone 16 iOS 18.5)

### Architecture Pattern

The app follows **MVVM (Model-View-ViewModel)** architecture:
- **Models**: Data structures and business entities
- **Views**: SwiftUI user interface components
- **ViewModels**: Business logic and state management
- **Services**: External API integrations and utilities

## 2. Repository Structure

```
PRPs-agentic-eng/
├── VoiceControlApp/                    # Main iOS app source code
│   ├── VoiceControlAppApp.swift       # App entry point with Firebase config
│   ├── ContentView.swift              # Root view with auth flow
│   ├── VoiceControlMainView.swift     # Main app interface
│   ├── Info.plist                     # URL schemes & permissions
│   ├── GoogleService-Info.plist       # Firebase configuration
│   ├── VoiceControlApp.entitlements   # App capabilities
│   │
│   ├── Authentication/                # Complete auth system
│   │   ├── Components/               # UI components (GoogleSignInButton)
│   │   ├── Models/                   # Auth models & state
│   │   ├── Services/                 # Auth services (Google, Firebase, Biometric)
│   │   ├── ViewModels/               # Auth business logic
│   │   └── Views/                    # Auth screens
│   │
│   ├── SpeechRecognition/            # Speech-to-text system
│   │   ├── AssemblyAIStreamer.swift  # Real-time streaming client
│   │   ├── AudioManager.swift        # Audio capture & processing
│   │   └── Models/                   # Speech processing models
│   │
│   └── Shared/                       # Common utilities
│       ├── Components/               # Reusable UI components
│       ├── Extensions/               # Swift extensions
│       └── Utils/                    # Helper utilities
│
├── VoiceControlApp.xcodeproj/         # Xcode project files
├── PRPs/                             # Product Requirement Prompts methodology
├── docs/                             # Project documentation
│   ├── assemblyai/                   # Speech API documentation
│   └── yamaha-rcp/                   # Mixer control documentation
├── ComputerReceiver/                 # Python utilities for testing
├── mobile-mcp-ios/                   # Mobile control protocol
├── CLAUDE.md                         # Claude Code project instructions
└── README.md                         # Project overview
```

### Key Directories Explained

- **`VoiceControlApp/`**: Main iOS application source code
- **`Authentication/`**: Complete authentication system with Google OAuth, Firebase, and biometric auth
- **`SpeechRecognition/`**: Real-time speech processing and AssemblyAI integration
- **`Shared/`**: Reusable components, extensions, and utilities
- **`PRPs/`**: Product Requirement Prompts for AI-assisted development
- **`docs/`**: Technical documentation and API references
- **`ComputerReceiver/`**: Python utilities for testing voice commands

## 3. Getting Started

### Prerequisites

**Required Software:**
- **macOS**: macOS 13.0+ (Ventura or later)
- **Xcode**: Version 15.0 or later
- **iOS Simulator**: iPhone 16 iOS 18.5 (specific requirement)
- **Command Line Tools**: `xcode-select --install`
- **ios-deploy**: For simulator deployment

**Optional but Recommended:**
- **Claude Code**: For AI-assisted development
- **Git**: Version control (should be pre-installed)

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone [repository-url]
   cd PRPs-agentic-eng
   ```

2. **Install ios-deploy** (if not already installed)
   ```bash
   npm install -g ios-deploy
   # or
   brew install ios-deploy
   ```

3. **Open the Project in Xcode**
   ```bash
   open VoiceControlApp.xcodeproj
   ```

4. **Set Up Simulator**
   - Open Xcode → Window → Devices and Simulators
   - Add iPhone 16 simulator running iOS 18.5
   - Note the device ID: `734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8`

### Running the Project

**CRITICAL: Always use iPhone 16 iOS 18.5 simulator**

```bash
# Fast build + install + launch to iPhone 16 iOS 18.5 simulator
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphonesimulator/VoiceControlApp.app -i 734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8
```

This command:
- Builds the iOS app for simulator target
- Installs to iPhone 16 iOS 18.5 simulator
- Launches the app automatically
- Shows console logs in terminal

### Running Tests

Currently, the project uses manual testing on the iPhone 16 iOS 18.5 simulator. Test the following flows:

1. **Authentication Flow**
   - Google Sign-In
   - Logout functionality
   - Session persistence

2. **Speech Recognition**
   - Microphone permissions
   - Real-time transcription
   - Audio capture quality

3. **Core Navigation**
   - Main interface
   - Settings access
   - Error handling

## 4. Key Components

### Entry Points

- **`VoiceControlAppApp.swift:12`**: App initialization with Firebase and Google Sign-In setup
- **`ContentView.swift:1`**: Root view with authentication flow and main UI logic
- **`VoiceControlMainView.swift`**: Main application interface post-authentication

### Authentication System

**Core Files:**
- **`Authentication/ViewModels/AuthenticationManager.swift`**: Central auth state management
- **`Authentication/Services/GoogleSignInService.swift`**: Google OAuth implementation
- **`Authentication/Services/FirebaseAuthService.swift`**: Firebase Auth integration
- **`Authentication/Services/BiometricService.swift`**: Face ID/Touch ID authentication

**Key Features:**
- Secure token management via Keychain
- Automatic session restoration
- Biometric authentication fallback
- Comprehensive error handling

### Speech Recognition System

**Core Files:**
- **`SpeechRecognition/AssemblyAIStreamer.swift`**: Real-time speech streaming client
- **`SpeechRecognition/AudioManager.swift`**: Audio capture and processing
- **`SpeechRecognition/Models/TranscriptionModels.swift`**: Speech processing models

**Features:**
- Real-time audio streaming to AssemblyAI
- WebSocket-based communication
- Configurable transcription settings
- Error recovery and reconnection

### Configuration Files

- **`Info.plist`**: URL schemes, permissions, and app metadata
- **`GoogleService-Info.plist`**: Firebase configuration with OAuth client IDs
- **`VoiceControlApp.entitlements`**: App capabilities and security settings

## 5. Development Workflow

### Standard Development Cycle

1. **Make Changes**: Edit Swift files in Xcode or your preferred editor
2. **Build & Deploy**: Use the fast ios-deploy command to iPhone 16 iOS 18.5 simulator
3. **Test Manually**: Comprehensive testing on the required simulator
4. **Capture Logs**: Use buffer-based log commands when debugging
5. **Iterate**: Quick cycles with hot reloading enabled

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "feat: implement feature description"

# Push and create PR
git push origin feature/your-feature-name
```

### Code Organization Guidelines

- **Feature-based folders**: Group related functionality (Authentication/, SpeechRecognition/)
- **Service layer**: External API integrations (Google, Firebase, AssemblyAI)
- **Shared components**: Reusable UI and utility components
- **Clear model separation**: Distinct data model definitions

### Testing Strategy

- **Manual Testing**: Primary testing method on iPhone 16 iOS 18.5 simulator
- **Authentication Flow**: Test sign-in, logout, session persistence
- **Speech Features**: Test microphone permissions and real-time transcription
- **Network Scenarios**: Test various connectivity conditions

## 6. Architecture Decisions

### Design Patterns

**MVVM Architecture:**
- **Views**: SwiftUI components focused on UI rendering
- **ViewModels**: Business logic and state management with @Published properties
- **Models**: Data structures and business entities
- **Services**: External integrations and utilities

**Dependency Injection:**
- Services are injected into ViewModels
- Clear separation of concerns
- Testable architecture

**State Management:**
- ObservableObject pattern for ViewModels
- @Published properties for reactive UI updates
- Centralized state in key managers (AuthenticationManager)

### Security Measures

- **Keychain Integration**: Secure token storage
- **Biometric Authentication**: Face ID/Touch ID support
- **Firebase Security**: Production-ready auth rules
- **No Sensitive Logging**: Never log tokens, passwords, or personal data

### Performance Optimizations

- **Hot Reloading**: Rapid development with HotSwiftUI
- **Efficient State Updates**: Minimal re-renders with proper @Published usage
- **Memory Management**: Proper lifecycle handling for WebSocket connections

## 7. Common Tasks

### Adding a New Authentication Method

1. **Create Service**: Add new service in `Authentication/Services/`
2. **Extend Models**: Update `AuthenticationState.swift` and error models
3. **Update ViewModel**: Modify `AuthenticationManager.swift`
4. **Add UI Components**: Create new view in `Authentication/Views/`
5. **Test Integration**: Verify with existing auth flow

### Adding a New Speech Feature

1. **Extend Models**: Update `TranscriptionModels.swift`
2. **Modify Streamer**: Update `AssemblyAIStreamer.swift`
3. **Update Configuration**: Modify `StreamingConfig.swift`
4. **Test Real-time**: Verify on iPhone 16 iOS 18.5 simulator

### Adding a New API Endpoint

1. **Create Service**: Add service class in appropriate feature folder
2. **Define Models**: Create request/response models
3. **Add Error Handling**: Implement comprehensive error handling
4. **Integrate with ViewModel**: Connect to existing state management
5. **Test Network Scenarios**: Verify connectivity edge cases

### Debugging Common Issues

1. **Authentication Failures**:
   ```bash
   # Check OAuth logs
   tail -300 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8/data/Library/Logs/system.log | grep -E "(Google|OAuth|blocked)" | head -20
   ```

2. **Speech Recognition Issues**:
   ```bash
   # Check app logs
   tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8/data/Library/Logs/system.log | grep VoiceControlApp | head -30
   ```

3. **Build Failures**: Check Xcode project settings and ensure all dependencies are resolved

## 8. Potential Gotchas

### Critical Requirements

- **⚠️ iPhone 16 iOS 18.5 Simulator Only**: Never use physical device or other simulators
- **⚠️ URL Scheme Configuration**: Required for Google OAuth (breaks without proper setup)
- **⚠️ Firebase Configuration**: `GoogleService-Info.plist` must be correctly configured
- **⚠️ Microphone Permissions**: Required for speech recognition functionality

### Known Issues

1. **iOS 26 Compatibility**: FBSceneErrorDomain crashes on newer iOS versions
2. **Firebase Auth in Simulator**: Google Sign-In is bypassed in simulator (by design)
3. **Hot Reloading**: Sometimes requires manual restart for major changes
4. **Log Capture**: Must use buffer-based commands (max 5 seconds)

### Configuration Dependencies

- **Google Cloud Console**: OAuth consent screen configuration required for production
- **Firebase Project**: Must be properly linked and configured
- **AssemblyAI API**: Requires valid API key for speech recognition
- **Bundle ID**: Must match `com.voicecontrol.app` for OAuth to work

### Performance Considerations

- **WebSocket Connections**: Properly close connections to prevent memory leaks
- **Audio Processing**: Monitor memory usage during continuous recording
- **State Updates**: Avoid excessive @Published updates for better performance

## 9. Documentation and Resources

### Project Documentation

- **`CLAUDE.md`**: Complete project instructions for Claude Code
- **`README.md`**: Project overview and PRP methodology
- **`docs/assemblyai/`**: Speech recognition API documentation
- **`docs/yamaha-rcp/`**: Mixer control protocol documentation

### External Resources

- **Firebase Console**: https://console.firebase.google.com/
- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
- **AssemblyAI Docs**: https://www.assemblyai.com/docs/
- **SwiftUI Documentation**: https://developer.apple.com/documentation/swiftui/

### API Documentation

- **Firebase Auth**: Built-in authentication with Google integration
- **AssemblyAI Streaming**: Real-time speech-to-text API
- **Yamaha RCP**: Professional mixer control protocol
- **Starscream WebSocket**: Real-time communication library

## 10. Next Steps - Onboarding Checklist

### Environment Setup ✅
- [ ] Install Xcode 15.0+
- [ ] Install ios-deploy
- [ ] Clone repository
- [ ] Open project in Xcode
- [ ] Set up iPhone 16 iOS 18.5 simulator

### First Run ✅
- [ ] Build project successfully
- [ ] Deploy to iPhone 16 iOS 18.5 simulator using fast command
- [ ] See app launch without crashes
- [ ] Navigate through authentication flow
- [ ] Test microphone permissions

### Code Exploration ✅
- [ ] Read `VoiceControlAppApp.swift` (entry point)
- [ ] Explore `Authentication/` folder structure
- [ ] Review `SpeechRecognition/` implementation
- [ ] Understand MVVM pattern usage
- [ ] Examine shared components

### Make First Change ✅
- [ ] Make a small UI change (e.g., button text)
- [ ] Build and test change
- [ ] Verify hot reloading works
- [ ] Create test commit
- [ ] Understand build process

### Advanced Understanding ✅
- [ ] Set up log monitoring workflow
- [ ] Test authentication flow end-to-end
- [ ] Understand Firebase integration
- [ ] Review AssemblyAI streaming implementation
- [ ] Explore Yamaha RCP documentation

### Production Readiness ✅
- [ ] Understand security considerations
- [ ] Review error handling patterns
- [ ] Learn debugging techniques
- [ ] Practice manual testing workflow
- [ ] Read production deployment considerations

### Ready to Contribute! 🚀
- [ ] Identify an area for your first contribution
- [ ] Create feature branch following naming conventions
- [ ] Implement feature following architecture patterns
- [ ] Test thoroughly on iPhone 16 iOS 18.5 simulator
- [ ] Document any new patterns or gotchas

## Development Best Practices

### ✅ DO:
- Use iPhone 16 iOS 18.5 simulator exclusively
- Follow MVVM architecture with clear separation
- Use SwiftUI best practices and existing patterns
- Implement proper error handling with Result types
- Use dependency injection for services
- Follow existing code style and naming conventions
- Use hot reloading for rapid UI development
- Capture logs efficiently (buffer-based, 5s max)

### ❌ DON'T:
- Use physical device or other simulators
- Hardcode credentials or sensitive data
- Skip URL scheme configuration
- Block main thread with heavy operations
- Log sensitive authentication data
- Create workarounds for manual setup requirements
- Continue when manual actions are needed

---

**Welcome to the team!** This project combines modern iOS development with AI-powered speech recognition and professional audio control. The codebase is designed for maintainability, security, and performance. Happy coding! 🎉