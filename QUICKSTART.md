# iOS Voice Control App - Quick Start Guide

Get up and running with the iOS Voice Control App in 15 minutes.

## 🚀 Prerequisites

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+**
- **Command Line Tools** (`xcode-select --install`)

## ⚡ Quick Setup (5 minutes)

### 1. Clone & Open Project
```bash
git clone [repository-url]
cd PRPs-agentic-eng
open VoiceControlApp.xcodeproj
```

### 2. Install ios-deploy
```bash
# Choose one:
npm install -g ios-deploy
# or
brew install ios-deploy
```

### 3. Set Up iPhone 16 iOS 18.5 Simulator ⚠️ CRITICAL
- Open Xcode → Window → Devices and Simulators
- Add iPhone 16 simulator running iOS 18.5
- **Device ID Required:** `5B1989A0-1EC8-4187-8A99-466B20CB58F2`
- **NEVER use physical device or other simulators** (causes compatibility issues)

## 🏃‍♂️ First Run (2 minutes)

### Build & Launch
```bash
# MANDATORY build command (bookmark this)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Then launch app on simulator
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app
```

**This command:**
- Builds the app for iPhone 16 iOS 18.5 simulator
- Creates build artifacts ready for deployment
- Second command launches the app automatically
- Use separate log commands when needed (see below)

### Expected Results
- ✅ App launches on iPhone 16 iOS 18.5 simulator
- ✅ Authentication screen appears
- ✅ Console shows no critical errors
- ✅ UI responds to touch

## 🧪 Quick Test (3 minutes)

### 1. Authentication Flow
- Tap "Sign In with Google" (bypassed in simulator)
- Should proceed to main interface
- Test logout functionality

### 2. Speech Recognition
- Grant microphone permissions when prompted
- Test voice input functionality
- Verify real-time transcription

### 3. Navigation
- Explore main interface
- Check settings access
- Verify smooth UI interactions

## 🔧 Development Commands

### Build & Deploy
```bash
# Primary build command (use this always)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Launch after successful build
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app
```

### Debug Logs (when needed) - Buffer-Based Only
```bash
# App logs (recent buffer, 5s max)
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30

# OAuth errors
tail -300 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(Google|OAuth|blocked)" | head -20

# App crashes
tail -100 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep -E "(VoiceControlApp.*error|crash)" | head -15
```

## 📱 Project Structure (Know This)

```
VoiceControlApp/
├── VoiceControlAppApp.swift          # App entry point
├── ContentView.swift                 # Root view with auth
├── VoiceControlMainView.swift        # Main interface
│
├── Authentication/                   # Auth system
│   ├── Services/                    # Google, Firebase, Biometric
│   ├── ViewModels/                  # Auth logic
│   └── Views/                       # Auth screens
│
├── SpeechRecognition/               # Speech-to-text
│   ├── AssemblyAIStreamer.swift     # Real-time streaming
│   └── AudioManager.swift           # Audio processing
│
└── Shared/                          # Common utilities
    ├── Components/                  # Reusable UI
    ├── Extensions/                  # Swift extensions
    └── Utils/                       # Helpers
```

## 🎯 Key Tech Stack

- **Frontend:** SwiftUI + MVVM architecture
- **Auth:** Firebase + Google Sign-In + Biometrics
- **Speech:** AssemblyAI real-time streaming
- **Networking:** Starscream WebSocket
- **Hot Reload:** HotSwiftUI for rapid development

## ⚠️ Critical Rules

### ✅ ALWAYS USE:
- **iPhone 16 iOS 18.5 simulator** (Device ID: `5B1989A0-1EC8-4187-8A99-466B20CB58F2`)
- xcodebuild command for builds (not ios-deploy)
- Buffer-based log commands (5s max)

### ❌ NEVER USE:
- Physical device
- Other simulators
- Live log streaming
- Hardcoded credentials

## 🚨 Troubleshooting

### Build Fails
- Clean Xcode build folder (⌘⇧K)
- Check simulator is running
- Verify Device ID matches exactly

### App Crashes
- Check console logs for errors
- Verify microphone permissions
- Ensure Firebase config is present

### Authentication Issues
- Google Sign-In is bypassed in simulator (expected)
- Check URL schemes in Info.plist
- Verify Firebase configuration

## 📚 Next Steps

1. **Read Full Docs:** `ONBOARDING.md` for comprehensive guide
2. **Explore Code:** Start with `VoiceControlAppApp.swift`
3. **Make Changes:** Try editing UI text and rebuilding
4. **Join Development:** Follow MVVM patterns and existing conventions

## 🆘 Need Help?

- **Project Instructions:** `CLAUDE.md`
- **Full Onboarding:** `ONBOARDING.md`
- **Architecture Docs:** `docs/` folder
- **PRP Methodology:** `PRPs/README.md`

---

**🎉 You're ready to develop!** The app should be running on your iPhone 16 iOS 18.5 simulator. Start exploring the codebase and making your first changes.