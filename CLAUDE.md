# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this iOS Voice Control app.

## Project Overview

This is an **iOS Voice Control App** featuring enterprise-grade Google OAuth authentication and real-time speech-to-text capabilities. Built with SwiftUI and designed for iPhone X+ (iOS 16+) with Firebase backend services.

**Core Features:**
- 🔐 Enterprise Google Sign-In with Firebase Auth
- 🎙️ Real-time speech recognition via AssemblyAI streaming
- 🎛️ Yamaha RCP mixer control integration
- 📱 Native iOS SwiftUI interface with MVVM architecture
- 🔄 Hot reloading for rapid development

**📚 Developer Resources:**
- **`QUICKSTART.md`** - Get running in 15 minutes (setup + first build)
- **`ONBOARDING.md`** - Comprehensive developer guide (architecture, workflow, troubleshooting)

**Bundle ID:** `com.voicecontrol.app`

## 🤖 Technology Agents

**Available specialized agents in `claude_md_files_agents/` folder:**

- **Swift/iOS**: `CLAUDE-SWIFT-IOS-AGENT.md` - Scope error prevention, framework imports, type safety
- **React**: `CLAUDE-REACT.md` - Component patterns, type safety, testing  
- **Node.js**: `CLAUDE-NODE.md` - Server patterns, async/await, error handling

**To activate an agent, simply tell Claude:**
- "use Swift iOS agent"
- "use React agent" 
- "use Node agent"

**That's it.** No automatic detection - you control when to apply specific technology best practices.

## 🔥 MANDATORY: Use Physical iPhone Device Only

**CRITICAL RULE: NEVER use iOS Simulator for builds or testing. ALWAYS use Colin's physical iPhone device.**

For this iOS project, use the optimized CLI workflow that's 6x faster than default xcodebuild:

```bash
# REQUIRED: Fast build + install + launch to physical iPhone device
# (Network blocking hack applied for speed - blocks slow Apple provisioning servers)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14
```

**Why Physical Device Only:**
- Real-world testing conditions
- Actual performance metrics  
- Touch/gesture interaction testing
- Camera/sensor functionality
- Push notifications work properly
- Network conditions are realistic
- 6x faster than simulator builds

This command:
- Builds the iOS app (~10 seconds vs 67+ seconds default)  
- Installs to Colin's iPhone device (2b51e8a8e9ffe69c13296dd6673c5e0d47027e14)
- Launches the app automatically
- Shows console logs in terminal
- Uses optimized workflow with Apple server blocking for speed

### ❌ DO NOT USE THESE COMMANDS:
```bash
# NEVER USE SIMULATOR BUILDS:
xcodebuild -scheme VoiceControlApp -sdk iphonesimulator ...  # ❌ WRONG
xcodebuild -destination 'platform=iOS Simulator' ...        # ❌ WRONG
```

## iOS Log Capture Workflow

After deploying with the fast build command, capture device logs for debugging:

**Prerequisites:**
```bash
# Install libimobiledevice for device log access
brew install libimobiledevice
```

**Past Log Buffer Capture:**

When you say "grab logs", Claude retrieves recent logs from iOS device buffer - captures your past testing activity without needing live capture during testing.

```bash
# PAST LOGS ONLY (5s max) - Recent buffer, no live streaming
tail -200 /var/log/system.log | grep VoiceControlApp | head -30

# OAUTH/GOOGLE ERRORS - Past authentication issues  
tail -300 /var/log/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# APP CRASHES - Past error buffer
tail -100 /var/log/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

**CRITICAL: All log commands must complete within 5 seconds and only read past buffer logs - never live stream.**

**Buffer-Based Log Workflow:**
1. **Build & Deploy**: Claude launches app to iPhone
2. **Manual Testing**: You test freely - no logging interference 
3. **Request Logs**: Say "grab logs" to get recent buffer:
   - "grab logs" → MINIMAL (50 lines, app-only)
   - "grab verbose logs" → VERBOSE (200 lines, includes UIKit)
   - "grab error logs" → ERROR HUNTING (crashes only)
4. **Analysis**: Claude analyzes your past testing activity from iOS buffer
5. **Iterate**: Build → Test → Grab → Analyze → Repeat

## 🛑 MANDATORY: Universal Manual Action Stop Rule

**META RULE: When you discover that ANY task requires manual actions that Claude Code terminal cannot perform agentically, you MUST:**

1. **Stop implementation immediately** - Do not continue coding or create workarounds
2. **Clearly identify what manual action is needed** - Be specific about what the user must do
3. **Explain why Claude Code cannot complete this step agentically** - Cannot access GUI, web interfaces, IDE settings, etc.
4. **Provide exact instructions for the user** - Step-by-step guidance
5. **Wait for user confirmation** - Do not proceed until the user has completed the manual steps

### Pattern:
```
🛑 MANUAL ACTION REQUIRED

**[Task] cannot be completed without [specific manual action].**

What you need to do:
1. [Step 1]
2. [Step 2] 
3. [Step 3]

After completing these steps, I can help you:
- [Next automated steps]
```

**This rule applies to ANY manual action, including but not limited to:**
- Xcode project settings (URL schemes, capabilities, build settings)
- Package dependencies requiring GUI installation
- IDE-specific configurations
- External service configurations (Google Cloud, Firebase, etc.)
- System dependencies requiring admin access
- Development certificates or signing
- Database schemas requiring DBA approval
- Any GUI-based configuration that terminal tools cannot access

## Current Technology Stack

**Frontend:**
- Swift 5.9+ with SwiftUI
- MVVM architecture pattern
- ObservableObject state management
- Hot reloading (InjectionNext + HotSwiftUI)

**Backend & Services:**
- Firebase (Auth, Database, Firestore, Functions)
- Google Sign-In SDK 9.0.0
- AssemblyAI real-time streaming API
- Starscream WebSocket library

**Development Tools:**
- Xcode 15.0+
- ios-deploy (6x faster than Xcode builds)
- libimobiledevice (device logging)

## Project Structure

```
VoiceControlApp/
├── VoiceControlAppApp.swift          # App entry point with Firebase config
├── ContentView.swift                 # Root view with auth flow
├── VoiceControlMainView.swift        # Main app interface
├── Info.plist                        # URL schemes & permissions
├── GoogleService-Info.plist          # Firebase configuration
├── VoiceControlApp.entitlements      # App capabilities
│
├── Authentication/                   # Complete auth system
│   ├── Components/                  # UI components (GoogleSignInButton)
│   ├── Models/                      # Auth models & state
│   ├── Services/                    # Auth services (Google, Firebase, Biometric)
│   ├── ViewModels/                  # Auth business logic
│   └── Views/                       # Auth screens
│
├── SpeechRecognition/               # Speech-to-text system
│   ├── AssemblyAIStreamer.swift     # Real-time streaming client
│   ├── AudioManager.swift           # Audio capture & processing
│   └── Models/                      # Speech processing models
│
└── Shared/                          # Common utilities
    ├── Components/                  # Reusable UI components
    ├── Extensions/                  # Swift extensions
    └── Utils/                       # Helper utilities
```

## Key Files & Components

**Entry Points:**
- **`VoiceControlAppApp.swift:12`**: App initialization with Firebase and Google Sign-In setup
- **`ContentView.swift:1`**: Root view with authentication flow and main UI logic
- **`VoiceControlMainView.swift`**: Main application interface post-authentication

**Authentication System:**
- **`Authentication/ViewModels/AuthenticationManager.swift`**: Central auth state management
- **`Authentication/Services/GoogleSignInService.swift`**: Google OAuth implementation
- **`Authentication/Services/FirebaseAuthService.swift`**: Firebase Auth integration
- **`Authentication/Services/BiometricService.swift`**: Face ID/Touch ID authentication

**Speech Recognition:**
- **`SpeechRecognition/AssemblyAIStreamer.swift`**: Real-time speech streaming client
- **`SpeechRecognition/AudioManager.swift`**: Audio capture and processing
- **`SpeechRecognition/Models/TranscriptionModels.swift`**: Speech processing models

**Configuration:**
- **`Info.plist`**: URL schemes (`com.googleusercontent.apps.1020288809254-gs8jhl1ak8oi5rasarpc1i5cq28sokjv`) and microphone permissions
- **`GoogleService-Info.plist`**: Firebase configuration with OAuth client IDs
- **`VoiceControlApp.entitlements`**: App capabilities and security settings

## Development Workflow

**Standard Development Cycle:**
1. **Make changes** to Swift files in Xcode
2. **Build and deploy** using fast ios-deploy command (6x faster)
3. **Test manually** on physical iPhone device (required)
4. **Capture logs** when needed using buffer-based commands (5s max)
5. **Iterate** quickly with hot reloading enabled

**Architecture Guidelines:**
- **MVVM Pattern**: Separate Views, ViewModels, and Services
- **Dependency Injection**: Services injected into ViewModels
- **State Management**: @Published properties with ObservableObject
- **Error Handling**: Result types with custom error models
- **Security**: Never log sensitive data (tokens, passwords)

**Code Organization:**
- **Modular Structure**: Feature-based folders (Authentication/, SpeechRecognition/)
- **Service Layer**: External API integrations (Google, Firebase, AssemblyAI)
- **Shared Components**: Reusable UI and utility components
- **Model Separation**: Clear data model definitions

**Testing Approach:**
- **Manual Testing**: Primary method on physical device
- **Authentication Flow**: Test sign-in, logout, session persistence
- **Speech Features**: Test microphone permissions and real-time transcription
- **Network Scenarios**: Test various connectivity conditions

## Development Best Practices

**✅ DO:**
- Use physical iPhone device (6x faster, real conditions)
- Follow MVVM architecture with clear separation
- Use SwiftUI best practices and existing patterns
- Implement proper error handling with Result types
- Use dependency injection for services
- Follow existing code style and naming conventions
- Use hot reloading for rapid UI development
- Capture logs efficiently (buffer-based, 5s max)

**❌ DON'T:**
- Use iOS Simulator (slower, unrealistic)
- Hardcode credentials or sensitive data
- Skip URL scheme configuration (breaks OAuth)
- Create workarounds for manual setup requirements
- Continue when manual actions are needed
- Block main thread with heavy operations
- Log sensitive authentication data
- Use live streaming for log capture

## Google Cloud Console URLs

**OAuth Consent Screen (Test Users):**
```
https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
```

**Google Cloud Project Overview:**
```
https://console.cloud.google.com/home/dashboard?project=project-1020288809254
```

## 🎯 MANDATORY: Proactive Direct URL Rule

**When giving manual web navigation instructions (because Claude Code cannot access GUIs), ALWAYS proactively provide direct URLs first.**

**Auto-detect scenarios requiring manual web action and immediately provide direct URLs:**

- OAuth/Cloud console configuration → Provide direct console URLs
- IDE settings that require GUI → Provide direct documentation/settings URLs  
- External service setup → Provide direct service URLs
- Account/billing configuration → Provide direct account URLs

**Examples:**
- "You need to add test users in OAuth consent screen" → Immediately provide: `https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254`
- "Configure Firebase authentication" → Immediately provide: `https://console.firebase.google.com/project/PROJECT_ID/authentication`
- "Set up Apple Developer certificates" → Immediately provide: `https://developer.apple.com/account/resources/certificates/list`

**Pattern: Direct URL first, then step-by-step instructions.**

**Initiative rule: Don't wait for user to ask for URLs - proactively provide them when giving any manual web navigation instructions.**

Remember: When external service configuration is needed (Google Cloud, Firebase, etc.), **STOP** and request manual user action rather than creating workarounds.

## 📚 Documentation

**Project docs in `/docs/` folder:**
- **AssemblyAI**: `/docs/assemblyai/` - Speech-to-text API docs
- **Yamaha RCP**: `/docs/yamaha-rcp/METAMETA-YAMAHA-RCP.md` - Mixer control context
- **Quick Reference**: `/docs/yamaha-rcp/yamaha-rcp-quick-reference.md` - Command syntax