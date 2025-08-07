# Android Voice Control App - Developer Onboarding Guide

Welcome to the Android Voice Control App! This comprehensive guide will help you understand the codebase, set up your development environment, and start contributing to the project.

## Table of Contents
- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Key Components](#key-components)
- [Architecture](#architecture)
- [Development Workflow](#development-workflow)
- [Common Tasks](#common-tasks)
- [Testing](#testing)
- [Potential Gotchas](#potential-gotchas)
- [Documentation](#documentation)
- [Onboarding Checklist](#onboarding-checklist)

## Project Overview

The **Android Voice Control App** is the Android version of an iOS Voice Control application, featuring enterprise-grade authentication and real-time speech-to-text capabilities for controlling professional audio equipment.

### Main Features
- 🔐 **Enterprise Google Sign-In** with Firebase Authentication
- 🎙️ **Real-time Speech Recognition** via AssemblyAI streaming API
- 🎛️ **Yamaha RCP Mixer Control** integration for professional audio
- 📱 **Modern Android UI** with Jetpack Compose and Material Design 3
- 🔄 **MVVM Architecture** with Hilt dependency injection
- 💳 **Subscription Management** with Google Play Billing
- 🔒 **Biometric Authentication** (fingerprint/face unlock)
- 📊 **Firebase Analytics** and Crashlytics integration

### Bundle ID
`com.voicecontrol.app`

### Target Users
- Professional audio engineers
- Musicians and producers
- Live sound operators
- Anyone needing voice-controlled audio equipment

## Tech Stack

### Core Technologies
- **Language**: Kotlin 1.9.22
- **Platform**: Android (API 28-34, Android 9.0+)
- **UI Framework**: Jetpack Compose with Material Design 3
- **Architecture**: MVVM (Model-View-ViewModel)
- **Dependency Injection**: Hilt (Dagger)
- **Build System**: Gradle with Kotlin DSL

### Key Dependencies
- **Firebase BOM 32.7.0**: Authentication, Firestore, Analytics, Crashlytics
- **Google Play Services**: Auth 20.7.0, Billing 6.1.0
- **Jetpack Compose BOM 2024.02.00**: UI framework
- **Navigation Compose 2.7.6**: Navigation
- **Coroutines 1.7.3**: Asynchronous programming
- **OkHttp 4.12.0**: Networking
- **Biometric 1.1.0**: Fingerprint/face authentication
- **Security Crypto 1.1.0**: Encrypted storage
- **Accompanist 0.32.0**: System UI and permissions

### External APIs
- **AssemblyAI**: Real-time speech-to-text streaming
- **Firebase**: Authentication, database, analytics
- **Google Sign-In**: OAuth authentication
- **Yamaha RCP**: Mixer control protocol

## Repository Structure

```
AndroidVoiceControlApp/
├── app/
│   ├── build.gradle.kts              # App-level build configuration
│   └── src/main/java/com/voicecontrol/app/
│       ├── MainActivity.kt           # Main entry point
│       ├── VoiceControlApplication.kt # Application class
│       │
│       ├── authentication/           # Authentication system
│       │   ├── model/               # Auth data models
│       │   ├── service/             # Auth services (Firebase, Google, Biometric)
│       │   └── viewmodel/           # Auth business logic
│       │
│       ├── di/                      # Dependency injection modules
│       │   ├── ApplicationModule.kt # Core DI setup
│       │   ├── AuthenticationModule.kt
│       │   └── NetworkModule.kt
│       │
│       ├── network/                 # Network layer
│       │   ├── model/               # Network data models
│       │   └── service/             # RCP network client
│       │
│       ├── speech/                  # Speech recognition
│       │   ├── model/               # Speech data models
│       │   └── service/             # AssemblyAI integration
│       │
│       ├── ui/                      # UI layer
│       │   ├── component/           # Reusable components
│       │   ├── navigation/          # Navigation setup
│       │   ├── screen/              # Screen composables
│       │   ├── theme/               # Material Design theme
│       │   └── viewmodel/           # UI ViewModels
│       │
│       └── voice/                   # Voice command processing
│           ├── model/               # Voice command models
│           └── service/             # Command processing logic
│
├── build.gradle.kts                 # Project-level build configuration
├── gradle.properties               # Gradle properties
├── local.properties               # Local configuration (API keys)
└── settings.gradle.kts            # Gradle settings

# Additional project resources:
├── PRPs/                           # Product Requirement Prompts
├── docs/                          # Documentation
├── ComputerReceiver/              # Testing utilities
└── voice-command-tester/          # Voice command testing tools
```

## Getting Started

### Prerequisites
- **Android Studio**: Hedgehog (2023.1.1) or newer
- **JDK**: 17 or 21 (embedded in Android Studio)
- **Android SDK**: API levels 28-34
- **Git**: For version control
- **Firebase account**: For backend services
- **AssemblyAI API key**: For speech recognition

### Environment Setup

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd AndroidVoiceApp/Ios-Voice-Control
   ```

2. **Open in Android Studio**
   - Launch Android Studio
   - Open the `AndroidVoiceControlApp` folder
   - Wait for Gradle sync to complete

3. **Configure API Keys**
   Create/update `local.properties`:
   ```properties
   sdk.dir=/path/to/Android/sdk
   ASSEMBLYAI_API_KEY=your_assemblyai_api_key_here
   KEYSTORE_PASSWORD=your_keystore_password
   KEY_ALIAS=your_key_alias  
   KEY_PASSWORD=your_key_password
   ```

4. **Firebase Setup**
   - Add your `google-services.json` to `app/` directory
   - Ensure Firebase project is configured with:
     - Authentication (Google Sign-In)
     - Firestore Database
     - Analytics
     - Crashlytics

### Build and Run

1. **Select Build Variant**
   - Debug: `app.debug` (development)
   - Release: `app.release` (production)

2. **Build the Project**
   ```bash
   ./gradlew assembleDebug
   ```

3. **Run on Device/Emulator**
   - Connect Android device or start emulator
   - Click "Run" in Android Studio or:
   ```bash
   ./gradlew installDebug
   ```

4. **Verify Installation**
   - App launches successfully
   - Google Sign-In flow works (may require real device)
   - Speech recognition permissions requested
   - Basic UI navigation functional

## Key Components

### Application Entry Points

#### VoiceControlApplication.kt
Main application class with Hilt setup and Firebase initialization.
```kotlin
@HiltAndroidApp
class VoiceControlApplication : Application()
```
- Equivalent to iOS `VoiceControlAppApp.swift`
- Handles app lifecycle and global configuration
- Memory management and logging

#### MainActivity.kt
Main activity with Compose setup and navigation.
```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity()
```
- Equivalent to iOS `ContentView.swift`
- Edge-to-edge display configuration
- Authentication flow coordination

### Core Services

#### Authentication Layer
- **FirebaseAuthService**: Firebase Authentication integration
- **GoogleSignInService**: Google OAuth implementation
- **BiometricAuthService**: Fingerprint/face unlock
- **SecureStorageService**: Encrypted local storage

#### Speech Recognition
- **AssemblyAIStreamer**: Real-time speech streaming
- **AudioManager**: Audio capture and processing
- **SpeechRecognitionService**: Main speech coordinator

#### Network Layer
- **RCPNetworkClient**: Yamaha mixer communication
- **NetworkSettings**: Network configuration management

### UI Architecture

#### Theme System (ui/theme/)
- **VoiceControlTheme**: Main theme configuration
- **VoiceControlColors**: Color palette
- **VoiceControlTypography**: Text styles
- **VoiceControlShapes**: Component shapes

#### Navigation (ui/navigation/)
- **VoiceControlNavigation**: Main navigation graph
- Handles authentication flow routing
- Screen transitions and deep linking

#### ViewModels (authentication/viewmodel/, ui/viewmodel/)
- **AuthenticationViewModel**: Auth state management
- **NetworkSettingsViewModel**: Network configuration
- MVVM pattern with StateFlow/LiveData

### Dependency Injection (di/)

#### ApplicationModule.kt
Core dependencies:
- Firebase instances
- Encrypted SharedPreferences
- Security components

#### AuthenticationModule.kt
Authentication-specific dependencies:
- Auth services
- Biometric components
- Secure storage

#### NetworkModule.kt
Network layer dependencies:
- HTTP clients
- Network configuration
- RCP services

## Architecture

### MVVM Pattern
```
View (Composable) ←→ ViewModel ←→ Repository/Service ←→ Data Source
```

#### Data Flow
1. **UI Events**: User interactions trigger ViewModel functions
2. **Business Logic**: ViewModels process events and update state
3. **Data Layer**: Services/repositories handle data operations
4. **State Updates**: UI recomposes based on state changes

#### State Management
- **StateFlow**: For reactive state in ViewModels
- **Compose State**: For local UI state
- **Hilt**: For dependency injection across layers

### Key Patterns

#### Repository Pattern
```kotlin
class AuthRepository @Inject constructor(
    private val firebaseAuth: FirebaseAuthService,
    private val googleSignIn: GoogleSignInService
)
```

#### Observer Pattern
```kotlin
// ViewModel
private val _authState = MutableStateFlow(AuthState.Initial)
val authState: StateFlow<AuthState> = _authState

// UI
val authState by viewModel.authState.collectAsState()
```

#### Dependency Injection
```kotlin
@Module
@InstallIn(SingletonComponent::class)
object ApplicationModule {
    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = FirebaseAuth.getInstance()
}
```

## Development Workflow

### Git Workflow
1. **Feature Branches**: `feature/description` or `fix/description`
2. **Main Branch**: `main` (protected, requires PR)
3. **Commit Format**: Follow conventional commits
   ```
   feat: add biometric authentication
   fix: resolve speech recognition crash
   docs: update API documentation
   ```

### Build Variants
- **Debug**: Development build with logging and debugging tools
- **Release**: Production build with obfuscation and optimization

### Code Style
- **Kotlin Coding Conventions**: Follow official Kotlin style guide
- **Compose Guidelines**: Use Compose best practices
- **Architecture**: Follow MVVM pattern consistently
- **Documentation**: Document public APIs and complex logic

### Testing Strategy
- **Unit Tests**: ViewModels, repositories, utilities
- **Integration Tests**: Service layer interactions  
- **UI Tests**: Compose UI testing with semantics
- **Manual Testing**: Authentication flows, speech recognition

## Common Tasks

### Adding a New Screen

1. **Create Composable**
   ```kotlin
   // ui/screen/NewScreen.kt
   @Composable
   fun NewScreen(
       navController: NavController,
       viewModel: NewViewModel = hiltViewModel()
   ) {
       // Screen content
   }
   ```

2. **Create ViewModel**
   ```kotlin
   @HiltViewModel
   class NewViewModel @Inject constructor(
       private val repository: NewRepository
   ) : ViewModel()
   ```

3. **Add to Navigation**
   ```kotlin
   // ui/navigation/VoiceControlNavigation.kt
   composable("new_screen") {
       NewScreen(navController)
   }
   ```

### Adding a New Service

1. **Create Service Interface**
   ```kotlin
   interface NewService {
       suspend fun performAction(): Result<Data>
   }
   ```

2. **Implement Service**
   ```kotlin
   class NewServiceImpl @Inject constructor(
       private val dependency: Dependency
   ) : NewService
   ```

3. **Add to DI Module**
   ```kotlin
   @Binds
   abstract fun bindNewService(impl: NewServiceImpl): NewService
   ```

### Adding Dependencies

1. **Update build.gradle.kts**
   ```kotlin
   implementation("com.example:library:1.0.0")
   ```

2. **Sync Project**
   - Android Studio → File → Sync Project with Gradle Files

3. **Add to ProGuard** (if needed for release builds)
   ```proguard
   -keep class com.example.library.** { *; }
   ```

### Database Changes

1. **Update Firestore Rules** (via Firebase Console)
2. **Update Data Models**
   ```kotlin
   @Serializable
   data class NewModel(
       val id: String,
       val data: String
   )
   ```

3. **Update Repository Layer**
   ```kotlin
   suspend fun saveNewModel(model: NewModel): Result<Unit>
   ```

## Testing

### Running Tests

```bash
# Unit tests
./gradlew testDebugUnitTest

# Instrumentation tests  
./gradlew connectedDebugAndroidTest

# Specific test class
./gradlew testDebugUnitTest --tests "AuthenticationViewModelTest"

# Code coverage
./gradlew testDebugUnitTestCoverage
```

### Test Structure

```kotlin
class AuthenticationViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()
    
    @Test
    fun `signIn should update auth state to success`() = runTest {
        // Given
        val viewModel = AuthenticationViewModel(mockRepository)
        
        // When
        viewModel.signIn(email, password)
        
        // Then
        assertEquals(AuthState.Authenticated, viewModel.authState.value)
    }
}
```

### Testing Tools
- **JUnit 4**: Test framework
- **MockK**: Mocking library for Kotlin
- **Turbine**: Testing Flow/StateFlow
- **Compose Test**: UI testing
- **Coroutine Test**: Testing suspend functions

## Potential Gotchas

### Development Environment

1. **Android Studio Version**: Ensure you're using Hedgehog or newer for Compose support
2. **Gradle JVM**: Set to JDK 17+ in Android Studio settings
3. **API Keys**: Never commit `local.properties` or hardcode API keys
4. **Firebase Config**: Ensure `google-services.json` matches your Firebase project

### Runtime Issues

1. **Speech Recognition**: Requires microphone permissions and real device testing
2. **Google Sign-In**: May not work properly on emulators without Google Play Services
3. **Biometric Auth**: Only works on real devices with biometric hardware
4. **Network Security**: HTTP traffic blocked on API 28+, use HTTPS
5. **Proguard**: May obfuscate Firebase/networking code in release builds

### Architecture Pitfalls

1. **Memory Leaks**: Always use `viewModelScope` for coroutines in ViewModels
2. **Context Leaks**: Use `@ApplicationContext` in DI, not Activity context
3. **State Management**: Use `StateFlow`/`LiveData` for UI state, not mutable properties
4. **Compose Recomposition**: Avoid side effects in Composable functions

### Firebase Gotchas

1. **Firestore Rules**: Default rules deny access - configure proper security rules
2. **Auth State**: Check for null user and handle auth state changes properly
3. **Offline Support**: Enable Firestore offline support for better UX
4. **Analytics**: May take 24-48 hours to appear in Firebase console

### Testing Challenges

1. **Coroutines**: Use `runTest` and `TestDispatcher` for coroutine testing
2. **Compose UI**: Use semantic properties and test tags for UI testing
3. **Firebase Mocking**: Complex to mock - consider using fake implementations
4. **Permissions**: Grant permissions in instrumentation tests

## Documentation

### Existing Documentation
- **README.md**: Project overview and PRP methodology
- **QUICKSTART.md**: Quick setup guide (to be created)
- **PRPs/**: Product Requirement Prompts for features
- **docs/assemblyai/**: Speech recognition API documentation
- **docs/yamaha-rcp/**: Audio mixer control documentation
- **claude_md_files/**: Development agent configurations

### Code Documentation
- **KDoc**: Document public APIs using KDoc format
- **Architecture Decision Records**: Document important technical decisions
- **API Documentation**: Maintain up-to-date API documentation

### External Resources
- [Android Developer Guide](https://developer.android.com/guide)
- [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
- [Firebase Android Documentation](https://firebase.google.com/docs/android/setup)
- [Material Design 3](https://m3.material.io/)
- [Hilt Documentation](https://dagger.dev/hilt/)

## Onboarding Checklist

### Environment Setup
- [ ] Android Studio installed and updated
- [ ] JDK 17+ configured
- [ ] Repository cloned successfully
- [ ] `local.properties` configured with API keys
- [ ] Firebase `google-services.json` added
- [ ] Project builds without errors

### First Run
- [ ] App launches successfully
- [ ] Debug build installs on device/emulator
- [ ] Basic navigation works
- [ ] Authentication screen appears
- [ ] No crash on startup

### Development Verification
- [ ] Made a small test change (e.g., text modification)
- [ ] Successfully built and deployed change
- [ ] Unit tests run successfully
- [ ] Code style/linting passes
- [ ] Git workflow understood

### Architecture Understanding
- [ ] MVVM pattern understood
- [ ] Dependency injection with Hilt clear
- [ ] Compose UI architecture familiar
- [ ] Firebase integration understood
- [ ] Key services and their purposes identified

### Next Steps
- [ ] Choose initial area to contribute (UI, auth, speech, networking)
- [ ] Review relevant documentation for chosen area
- [ ] Set up development tools (debugger, profiler)
- [ ] Join team communication channels
- [ ] Schedule architecture review with team lead

## Support and Resources

### Getting Help
- **Team Communication**: [Your team's communication channel]
- **Code Reviews**: Submit PRs for feedback
- **Documentation**: Refer to this guide and existing docs
- **Firebase Console**: Monitor errors and analytics

### Development Tools
- **Android Studio Profiler**: Performance monitoring
- **Layout Inspector**: UI debugging
- **Database Inspector**: Local database inspection
- **Logcat**: Runtime logging and debugging

### Useful Commands
```bash
# Clean build
./gradlew clean

# Check dependencies
./gradlew app:dependencies

# Lint check
./gradlew lintDebug

# Security scan
./gradlew app:checkDebugSources
```

---

Welcome to the team! This guide should get you up and running quickly. Don't hesitate to ask questions and contribute to improving this documentation as you learn the codebase.