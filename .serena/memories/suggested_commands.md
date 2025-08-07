# Suggested Commands for Android Voice Control App

## Prerequisites
- Java 17+ required: `java -version`
- Android SDK and ADB installed
- Physical device or emulator with API 28+

## Build & Run Commands
```bash
# Navigate to Android project
cd AndroidVoiceControlApp

# Build debug APK
./gradlew assembleDebug

# Install on device/emulator
./gradlew installDebug

# Build and install in one step
./gradlew assembleDebug && ./gradlew installDebug

# Clean build (when facing build issues)
./gradlew clean && ./gradlew assembleDebug
```

## Testing Commands
```bash
# Unit tests
./gradlew testDebugUnitTest

# Integration tests (requires connected device)
./gradlew connectedDebugAndroidTest

# Automated testing framework (RECOMMENDED)
cd ../android_testing_framework/
python3 android_mcp_tester.py --suite

# Interactive testing menu
python3 android_mcp_tester.py

# Live monitoring during development
python3 android_mcp_tester.py --live
```

## Logging & Debugging Commands
```bash
# App-specific logs (recommended - 5 second buffer)
adb logcat -t 200 | grep "VoiceControlApp\|com.voicecontrol.app" | head -30

# Authentication errors
adb logcat -t 300 | grep -E "(Google|OAuth|Firebase|Auth)" | head -20

# Crashes and fatal errors
adb logcat -t 100 | grep -E "(FATAL|AndroidRuntime|crash)" | head -15

# Speech recognition specific
adb logcat -t 200 | grep -E "(SpeechRecognition|AssemblyAI|AudioManager)" | head -25

# Real-time full log stream (use sparingly)
adb logcat | grep "VoiceControlApp"
```

## Linting & Code Quality
```bash
# Kotlin lint
./gradlew lintDebug

# Detekt static analysis
./gradlew detekt

# Format code (if configured)
./gradlew ktlintFormat
```

## Development Utilities
```bash
# List connected devices
adb devices

# Install APK manually
adb install app/build/outputs/apk/debug/app-debug.apk

# Uninstall app (for clean testing)
adb uninstall com.voicecontrol.app

# Clear app data (reset to first run)
adb shell pm clear com.voicecontrol.app

# Take screenshot
adb exec-out screencap -p > screenshot.png

# Record screen (4 minutes max)
adb shell screenrecord /sdcard/recording.mp4
```

## Git & Version Control
```bash
# Standard git commands work normally
git status
git add .
git commit -m "message"
git push origin main

# Branch management
git checkout -b feature/new-feature
git merge feature/new-feature
```

## MCP Server Usage
When working with Claude Code, these MCP servers are auto-configured:
- `mcp__serena__*` - Kotlin code analysis and editing
- `mcp__mobile__*` - Android device automation and testing  
- `mcp__context7__*` - Firebase/Compose/Hilt documentation
- `mcp__voice-mode__*` - Speech testing and audio validation
- `mcp__brave-search__*` - Current Android development practices