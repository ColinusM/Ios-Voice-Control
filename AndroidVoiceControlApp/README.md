# Android Voice Control App

Native Android implementation of the iOS Voice Control app with 100% feature parity.

## Project Status
🚧 **In Development** - Following PRP: `../PRPs/ios-to-android-conversion-parallel.md`

## Technology Stack
- **Language**: Kotlin 100%
- **UI Framework**: Jetpack Compose + Material Design 3
- **Architecture**: Clean Architecture + MVVM
- **Dependency Injection**: Hilt (Dagger)
- **Async**: Coroutines + Flow
- **Authentication**: Firebase Auth + Google Sign-In + Android Biometric
- **Speech Recognition**: AssemblyAI WebSocket streaming + Android Speech API
- **Network**: OkHttp3 + WebSocket
- **Testing**: JUnit 5 + MockK + Compose Testing

## Development Environment Setup

### Prerequisites
- Android Studio Arctic Fox or later
- Kotlin 1.9.0+
- Gradle 8.0+
- Java 17+
- Firebase CLI
- AssemblyAI API key

### Quick Start
```bash
# 1. Open Android Studio
# 2. Create new project in this directory
# 3. Configure Firebase following ../Firebase/ setup
# 4. Follow PRP implementation phases
```

## Project Structure
```
AndroidVoiceControlApp/
├── app/src/main/java/com/voicecontrol/app/
│   ├── authentication/          # Auth system
│   ├── speech/                 # Speech recognition  
│   ├── voicecommand/           # Voice processing
│   ├── network/                # RCP communication
│   └── ui/                     # Compose components
└── app/src/test/               # Unit tests
```

## Related Documentation
- **Implementation Guide**: `../PRPs/ios-to-android-conversion-parallel.md`
- **iOS Reference**: `../VoiceControlApp/` (original implementation)
- **Firebase Setup**: `../Firebase/`
- **Architecture Patterns**: `../claude_md_files/CLAUDE-JAVA-GRADLE.md`

## Development Commands

### Build & Test
```bash
./gradlew clean build
./gradlew testDebug testRelease
./gradlew connectedAndroidTest
```

### Code Quality
```bash
./gradlew ktlintCheck ktlintFormat
./gradlew detekt
./gradlew lint
```

### Performance
```bash
./gradlew benchmarkDebugAndroidTest
./gradlew jacocoTestReport
```

Ready to begin Android implementation following the comprehensive PRP! 🚀