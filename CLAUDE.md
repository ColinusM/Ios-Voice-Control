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
- **Technology Stack**: Swift 5.9+, SwiftUI, Firebase 11.15.0, Google Sign-In 9.0.0, AssemblyAI streaming

**Bundle ID:** `com.voicecontrol.app`

## 🤖 Technology Agents

**Available specialized agents in `claude_md_files/` folder:**

- **Swift/iOS**: `CLAUDE-SWIFT-IOS-AGENT.md` - Scope error prevention, framework imports, type safety
- **React**: `CLAUDE-REACT.md` - Component patterns, type safety, testing  
- **Node.js**: `CLAUDE-NODE.md` - Server patterns, async/await, error handling
- **Java Gradle**: `CLAUDE-JAVA-GRADLE.md` - Build system patterns
- **Python**: `CLAUDE-PYTHON-BASIC.md` - Python development patterns

**To activate an agent, simply tell Claude:**
- "use Swift iOS agent"
- "use React agent" 
- "use Node agent"

**That's it.** No automatic detection - you control when to apply specific technology best practices.

## 🔥 MANDATORY: Use iPhone 16 iOS 18.5 Simulator Only

**CRITICAL RULE: ALWAYS use iPhone 16 iOS 18.5 simulator for builds and testing. NEVER use physical device or other simulators.**

For this iOS project, use the optimized simulator workflow:

```bash
# REQUIRED: Build for iPhone 16 iOS 18.5 simulator
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Then launch the app on simulator (after successful build)
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app
```

**Why iPhone 16 iOS 18.5 Simulator Only:**
- Consistent testing environment
- No iOS 26 compatibility issues (FBSceneErrorDomain crashes)
- Firebase Authentication works properly
- Google Sign-In bypassed in simulator (as intended)
- Biometric authentication properly protected for simulator
- Auto-login testing functionality works
- Fast rebuild and deployment cycles

This command:
- Builds the iOS app for simulator target
- Builds for iPhone 16 iOS 18.5 simulator (5B1989A0-1EC8-4187-8A99-466B20CB58F2)
- Creates build artifacts for simulator
- Ready to launch with xcrun simctl command
- Uses proper xcodebuild for simulator target

### ❌ DO NOT USE THESE COMMANDS:
```bash
# NEVER USE PHYSICAL DEVICE:
ios-deploy -b .../Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14  # ❌ WRONG

# NEVER USE OTHER SIMULATORS:
ios-deploy -b .../Debug-iphonesimulator/VoiceControlApp.app -i [OTHER_SIMULATOR_ID]  # ❌ WRONG
```

## iOS Simulator Log Capture Workflow

After deploying with the fast build command, capture simulator logs for debugging:

**Simulator Log Capture:**

When you say "grab logs", Claude retrieves recent logs from iOS simulator buffer - captures your past testing activity without needing live capture during testing.

```bash
# SIMULATOR LOGS ONLY (5s max) - Recent buffer, no live streaming
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30

# OAUTH/GOOGLE ERRORS - Past authentication issues  
tail -300 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# APP CRASHES - Past error buffer
tail -100 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

**CRITICAL: All log commands must complete within 5 seconds and only read past buffer logs - never live stream.**

**Buffer-Based Log Workflow:**
1. **Build & Deploy**: Claude launches app to iPhone 16 iOS 18.5 simulator
2. **Manual Testing**: You test freely - no logging interference 
3. **Request Logs**: Say "grab logs" to get recent buffer:
   - "grab logs" → MINIMAL (50 lines, app-only)
   - "grab verbose logs" → VERBOSE (200 lines, includes UIKit)
   - "grab error logs" → ERROR HUNTING (crashes only)
4. **Analysis**: Claude analyzes your past testing activity from iOS simulator buffer
5. **Iterate**: Build → Test → Grab → Analyze → Repeat

## 🛑 MANDATORY: File Addition to Xcode Project Rule

**CRITICAL: Every time you create a new Swift file, you MUST add it to the Xcode project before building.**

**✅ WORKING Command for adding new files to build target:**
```bash
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && python3 -c "
import pbxproj
project = pbxproj.XcodeProject.load('VoiceControlApp.xcodeproj/project.pbxproj')
project.add_file('VoiceControlApp/Path/To/NewFile.swift', target_name='VoiceControlApp')
project.save()
print('✅ NewFile.swift added to VoiceControlApp target')
"
```

**Alternative method (if Python method fails):**
```bash
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && pbxproj file VoiceControlApp.xcodeproj VoiceControlApp/Path/To/NewFile.swift
```

**Examples of recent successful file additions:**
```bash
# EffectsProcessor.swift
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && python3 -c "
import pbxproj
project = pbxproj.XcodeProject.load('VoiceControlApp.xcodeproj/project.pbxproj')
project.add_file('VoiceControlApp/VoiceCommand/Services/EffectsProcessor.swift', target_name='VoiceControlApp')
project.save()
print('✅ EffectsProcessor.swift added to VoiceControlApp target')
"
```

**This applies to ALL new Swift files:**
- Service classes (ChannelProcessor, RoutingProcessor, EffectsProcessor, etc.)
- UI components
- Model files
- Extension files
- Test files

**NEVER attempt to build without adding new files to the project first.**

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
- Firebase iOS SDK 11.15.0 (Auth, Database, Firestore, Functions)
- Google Sign-In SDK 9.0.0
- AssemblyAI real-time streaming API
- Starscream WebSocket library 4.0.8
- AppAuth-iOS 2.0.0 for OAuth flows

**Development Tools:**
- Xcode 15.0+
- ios-deploy (simulator builds)
- iOS Simulator (iPhone 16 iOS 18.5 - Device ID: 5B1989A0-1EC8-4187-8A99-466B20CB58F2)
- HotSwiftUI 1.2.1 for hot reloading

**Key Dependencies (from Package.resolved):**
- Firebase iOS SDK 11.15.0
- Google Sign-In 9.0.0
- Starscream 4.0.8
- HotSwiftUI 1.2.1
- GoogleUtilities 8.1.0

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
2. **Build and deploy** using xcodebuild command to iPhone 16 iOS 18.5 simulator
3. **Test manually** on iPhone 16 iOS 18.5 simulator (required)
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
- **Manual Testing**: Primary method on iPhone 16 iOS 18.5 simulator
- **Authentication Flow**: Test Google sign-in (bypassed in simulator), logout, session persistence
- **Speech Features**: Test microphone permissions and real-time transcription
- **Network Scenarios**: Test various connectivity conditions
- **Biometric Auth**: Test Face ID/Touch ID simulation
- **Hot Reload**: Verify UI changes reflect immediately during development

**Testing Workflow:**
1. Build & deploy with xcodebuild command
2. Manual testing on iPhone 16 iOS 18.5 simulator
3. Capture logs when needed (buffer-based, 5s max)
4. Iterate with hot reloading for UI changes

## Development Best Practices

**✅ DO:**
- Use iPhone 16 iOS 18.5 simulator (stable, consistent)
- Follow MVVM architecture with clear separation
- Use SwiftUI best practices and existing patterns
- Implement proper error handling with Result types
- Use dependency injection for services
- Follow existing code style and naming conventions
- Use hot reloading for rapid UI development
- Capture logs efficiently (buffer-based, 5s max)

**❌ DON'T:**
- Use physical device or other simulators (compatibility issues)
- Hardcode credentials or sensitive data
- Skip URL scheme configuration (breaks OAuth)
- Create workarounds for manual setup requirements
- Continue when manual actions are needed
- Block main thread with heavy operations
- Log sensitive authentication data
- Use live streaming for log capture

## Common Development Tasks

### Adding New Authentication Method
1. Create service in `Authentication/Services/`
2. Extend `AuthenticationState.swift` and error models
3. Update `AuthenticationManager.swift`
4. Add UI components in `Authentication/Views/`
5. Test with iPhone 16 iOS 18.5 simulator

### Adding New Speech Feature
1. Extend models in `SpeechRecognition/Models/`
2. Modify `AssemblyAIStreamer.swift`
3. Update `StreamingConfig.swift`
4. Test real-time functionality

### Debugging Common Issues
1. **Build Failures**: Clean Xcode build folder (⌘⇧K), verify simulator
2. **Authentication Issues**: Check URL schemes in Info.plist, verify Firebase config
3. **Speech Recognition**: Verify microphone permissions, check AssemblyAI API key
4. **WebSocket Errors**: Check network connectivity, verify endpoint URLs

### Log Monitoring Commands
```bash
# Standard app logs (use this most often)
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30

# OAuth/authentication errors
tail -300 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# App crashes and errors
tail -100 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

## Google Cloud Console URLs

**OAuth Consent Screen (Test Users):**
```
https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
```

**Google Cloud Project Overview:**
```
https://console.cloud.google.com/home/dashboard?project=project-1020288809254
```

## Firebase Console URLs

**Firebase Project Overview:**
```
https://console.firebase.google.com/project/project-1020288809254/overview
```

**Firebase Authentication:**
```
https://console.firebase.google.com/project/project-1020288809254/authentication
```

**Firebase Database:**
```
https://console.firebase.google.com/project/project-1020288809254/firestore
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

**Developer Onboarding:**
- **`QUICKSTART.md`** - 15-minute setup guide with essential commands
- **`ONBOARDING.md`** - Comprehensive developer guide (120+ sections)
- **`README.md`** - Project overview and PRP methodology

**Project docs in `/docs/` folder:**
- **AssemblyAI**: `/docs/assemblyai/` - Speech-to-text API docs and examples
- **Yamaha RCP**: `/docs/yamaha-rcp/METAMETA-YAMAHA-RCP.md` - Mixer control context
- **Quick Reference**: `/docs/yamaha-rcp/yamaha-rcp-quick-reference.md` - Command syntax

**AI Development Resources:**
- **PRPs**: `/PRPs/` - Product Requirement Prompts methodology
- **Templates**: `/PRPs/templates/` - Structured prompt templates
- **AI Docs**: `/PRPs/ai_docs/` - Claude Code documentation
- **Technology Agents**: `/claude_md_files/` - Specialized development agents

**Configuration Files:**
- **`Info.plist`** - App permissions, URL schemes, bundle configuration
- **`GoogleService-Info.plist`** - Firebase and OAuth client configuration
- **`VoiceControlApp.entitlements`** - iOS app capabilities and security settings

## 🛠️ Development Environment

**Required Simulator Configuration:**
- **Simulator**: iPhone 16 iOS 18.5
- **Device ID**: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
- **Why This Specific Setup**: Consistent environment, Firebase compatibility, no iOS 26 crashes

**Build Command (Bookmark This):**
```bash
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build
```

**Hot Reloading**: Enabled with HotSwiftUI for rapid UI development cycles

## 📋 Project Status & Versions

**Current Version**: 1.0 (Build 1)
**iOS Deployment Target**: iOS 16.0+
**Xcode Compatibility**: 15.0+
**Swift Version**: 5.9+

**Recent Major Features:**
- ✅ Enterprise Google OAuth authentication
- ✅ Real-time AssemblyAI speech recognition
- ✅ Firebase backend integration
- ✅ Biometric authentication (Face ID/Touch ID)
- ✅ Yamaha RCP mixer control preparation
- ✅ Hot reloading development environment

**Architecture Health:**
- MVVM pattern consistently implemented
- Dependency injection in place
- Comprehensive error handling
- Security best practices followed
- Modular code organization

---

## 🚀 Quick Reference for Claude Code

**Essential Commands:**
1. **Build & Run**: Use the xcodebuild command with iPhone 16 iOS 18.5 simulator
2. **Debug**: Use buffer-based log commands (5s max)
3. **Develop**: Edit Swift files, leverage hot reloading
4. **Test**: Manual testing on required simulator only

**Key Files to Know:**
- `VoiceControlAppApp.swift` - Entry point
- `Authentication/ViewModels/AuthenticationManager.swift` - Auth state
- `SpeechRecognition/AssemblyAIStreamer.swift` - Speech processing
- `Info.plist` - App configuration
- `QUICKSTART.md` - Get running in 15 minutes
- `ONBOARDING.md` - Comprehensive developer guide

**Remember**: Always use iPhone 16 iOS 18.5 simulator, follow MVVM patterns, and stop for manual GUI actions.