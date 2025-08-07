# CLAUDE.md

**Android Voice Control App** - Kotlin 1.9.22, Jetpack Compose, Firebase 32.7.0, Hilt DI, AssemblyAI streaming
**Bundle ID:** `com.voicecontrol.app` | **Target:** Android 9.0+ (API 28+)

## MCP Servers (Auto-Use)
- **`mcp__context7__*`** - Firebase/Compose/Hilt docs  
- **`mcp__serena__*`** - Kotlin code analysis/editing
- **`mcp__mobile__*`** - Android testing/automation
- **`mcp__voice-mode__*`** - Speech testing
- **`mcp__brave-search__*`** - Current Android practices

## Build & Run (Java 17+ Required)
```bash
java -version  # Must be 17+
cd AndroidVoiceControlApp && ./gradlew assembleDebug
./gradlew installDebug
```

## Log Commands (5s max, buffer only)
```bash
# VLogger Structured Logs (🎙️ 🚀 ✅ ❌ 🔗)
adb logcat -d | grep -E "(VoiceRecordingViewModel|SpeechRecognitionService|AudioManager|VLogger|🎙️|🚀|✅|❌|🔗)" | tail -20

# App logs (basic)
adb logcat -t 200 | grep "VoiceControlApp\|com.voicecontrol.app" | head -30

# Voice recording (AssemblyAI WebSocket)
adb logcat -d | grep -E "(assemblyai|WebSocket|101 Switching)" | tail -10

# Audio hardware issues (emulator limitation)
adb logcat -d | grep -E "(android.hardware.audio|pcm_prepare|I/O error)" | tail -5

# Auth errors  
adb logcat -t 300 | grep -E "(Google|OAuth|Firebase|Auth)" | head -20

# Crashes
adb logcat -t 100 | grep -E "(FATAL|AndroidRuntime|crash)" | head -15
```

## VLogger Debug Notes
**⚠️ VLogger DEBUG logs filtered unless `BuildConfig.DEBUG=true`**
- Most VLogger calls use `VLogger.d()` (DEBUG level)  
- Release builds: Only INFO/WARN/ERROR logs show
- Emulator audio hardware: Prevents voice recording VLogger execution
- **Record button coordinates: (493, 2097)** - Use Mobile MCP for testing

## Testing Framework
```bash
cd android_testing_framework/
python3 android_mcp_tester.py --suite  # RECOMMENDED
```

## Manual Action Stop Rule
**🛑 STOP** when GUI/web config needed → provide direct URLs & wait for user

## Architecture 
**MVVM** | **Hilt DI** | **Compose UI** | **Feature-based packages**

## Key Paths
- `AndroidVoiceControlApp/app/src/main/java/com/voicecontrol/app/`
- `MainActivity.kt` - Entry point
- `authentication/` - Google/Firebase/Biometric auth  
- `speech/service/AssemblyAIStreamer.kt` - Real-time STT
- `ui/` - Compose screens & components
- `local.properties` - API keys

## Console URLs (Manual Actions)

**Google Cloud:**
- OAuth: https://console.cloud.google.com/apis/credentials/consent?project=project-1020288809254
- Project: https://console.cloud.google.com/home/dashboard?project=project-1020288809254

**Firebase:**  
- Overview: https://console.firebase.google.com/project/project-1020288809254/overview
- Auth: https://console.firebase.google.com/project/project-1020288809254/authentication
- Database: https://console.firebase.google.com/project/project-1020288809254/firestore

