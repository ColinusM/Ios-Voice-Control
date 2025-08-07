# Android Voice Control App - Quick Start Guide

Get up and running with the Android Voice Control App in 15 minutes.

## Prerequisites

- **Android Studio**: Hedgehog (2023.1.1) or newer
- **JDK**: 17+ (embedded in Android Studio)
- **Android device/emulator**: API 28+ (Android 9.0+)
- **AssemblyAI API key**: For speech recognition
- **Firebase account**: For authentication and backend

## Quick Setup (15 minutes)

### 1. Clone and Open (2 minutes)

```bash
git clone <repository-url>
cd AndroidVoiceApp/Ios-Voice-Control
```

Open `AndroidVoiceControlApp` folder in Android Studio.

### 2. Configure API Keys (5 minutes)

Create `AndroidVoiceControlApp/local.properties`:
```properties
sdk.dir=/path/to/Android/sdk
ASSEMBLYAI_API_KEY=your_assemblyai_api_key_here

# Optional - for release builds
KEYSTORE_PASSWORD=your_keystore_password
KEY_ALIAS=your_key_alias  
KEY_PASSWORD=your_key_password
```

### 3. Firebase Setup (5 minutes)

1. **Download config**: Get `google-services.json` from your Firebase project
2. **Add to project**: Place in `AndroidVoiceControlApp/app/` directory
3. **Verify services**: Ensure Firebase project has:
   - Authentication (Google provider enabled)
   - Firestore Database
   - Analytics
   - Crashlytics

### 4. Build and Run (3 minutes)

```bash
# From AndroidVoiceControlApp directory
./gradlew assembleDebug
./gradlew installDebug
```

Or in Android Studio: Click **Run** button.

## Verify Installation

✅ **Success indicators**:
- App launches without crash
- Authentication screen appears
- Google Sign-In button visible
- Microphone permission requested
- Basic navigation works

❌ **Common issues**:
- **Build error**: Check `google-services.json` placement
- **Sign-in not working**: Test on real device (emulator limitations)
- **Speech not working**: Grant microphone permissions

## Project Structure Quick Overview

```
AndroidVoiceControlApp/
├── app/src/main/java/com/voicecontrol/app/
│   ├── MainActivity.kt                    # App entry point
│   ├── VoiceControlApplication.kt         # Application class
│   ├── authentication/                    # Auth system
│   ├── speech/                           # Speech recognition
│   ├── ui/                              # Compose UI
│   └── di/                              # Dependency injection
```

## Essential Commands

```bash
# Build debug version
./gradlew assembleDebug

# Run tests
./gradlew testDebugUnitTest

# Install on device
./gradlew installDebug

# Clean build
./gradlew clean

# Lint check
./gradlew lintDebug
```

## Architecture Quick Reference

- **Language**: Kotlin
- **UI**: Jetpack Compose
- **Architecture**: MVVM
- **DI**: Hilt
- **Authentication**: Firebase + Google Sign-In
- **Speech**: AssemblyAI streaming
- **Database**: Firestore
- **Target**: Android 9.0+ (API 28-34)

## Next Steps

1. **Read full documentation**: `ANDROID_ONBOARDING.md`
2. **Explore features**: Try authentication and speech recognition
3. **Make first change**: Modify a text string and rebuild
4. **Join team**: Get access to Firebase console and team channels
5. **Choose contribution area**: UI, authentication, speech, or networking

## Development Tips

- **Use real device**: For Google Sign-In and speech features
- **Check Logcat**: For runtime debugging
- **Hot reload**: Compose supports live updates
- **Firebase console**: Monitor errors and analytics
- **Hilt integration**: All services are dependency injected

## Getting Help

- **Full guide**: `ANDROID_ONBOARDING.md`
- **Code documentation**: Inline KDoc comments
- **External docs**: Firebase, Compose, Hilt official documentation
- **Team communication**: [Your team channels]

---

**Total time**: ~15 minutes to working app  
**Next milestone**: Make your first contribution in 30 minutes