name: "iOS Firebase Authentication Integration - Comprehensive Implementation"
description: |

## Purpose

Implement a complete Firebase Authentication system for the iOS Voice Control app using modern SwiftUI patterns, comprehensive security practices, and autonomous validation capabilities.

## Core Principles

1. **Context is King**: Include ALL necessary Firebase documentation, SwiftUI patterns, and security best practices
2. **Validation Loops**: Provide executable tests and validation commands for autonomous verification
3. **Security First**: Implement proper token management, Keychain storage, and modern authentication flows
4. **Progressive Success**: Start with basic setup, validate, then add advanced features

---

## Goal

Create a production-ready Firebase Authentication system for the iOS Voice Control app that supports email/password authentication, Google Sign-In integration, secure token management, and prepares for future Apple Pay and AssemblyAI integrations.

## Why

- **User Security**: Implement industry-standard authentication with Firebase's proven security infrastructure
- **Scalability**: Foundation for future integrations (Apple Pay, Google Sign-In, AssemblyAI)
- **User Experience**: Seamless authentication flow with biometric support and secure session management
- **Development Efficiency**: Firebase reduces authentication complexity and provides robust user management
- **Compliance**: Meet iOS security guidelines and prepare for App Store review requirements

## What

A complete iOS authentication system featuring:

### Core Authentication Features
- Email/password registration and sign-in
- Google Sign-In integration (prepared for future implementation)
- Secure session management with automatic token refresh
- Biometric authentication (Face ID/Touch ID) for app access
- Password reset and account management flows

### Security Implementation
- Keychain-based secure token storage
- Automatic session persistence across app launches
- Proper error handling and user feedback
- Network security with certificate pinning preparation

### User Experience
- Modern SwiftUI authentication UI with proper accessibility
- Loading states and error messaging
- Onboarding flow for new users
- Account management interface

### Success Criteria

- [ ] Users can register with email/password and receive verification emails
- [ ] Users can sign in with email/password with proper error handling
- [ ] Authentication state persists across app launches using Keychain
- [ ] Password reset functionality works end-to-end
- [ ] Biometric authentication provides secure app access
- [ ] Google Sign-In integration is prepared (configuration ready)
- [ ] All Firebase security rules are properly configured
- [ ] Comprehensive error handling for all authentication scenarios
- [ ] Accessibility compliance for authentication flows
- [ ] Unit and UI tests achieve >90% coverage for authentication logic

## All Needed Context

### Documentation & References

```yaml
# VALIDATION STRATEGY REFERENCE - MUST READ
- docfile: Validation Strategies/1 - iOS-Firebase-Auth-Validation-Strategy.md
  why: Comprehensive 5-level autonomous validation strategy for iOS Firebase authentication
  critical: Use this complete validation framework for testing authentication implementation

# FIREBASE CORE DOCUMENTATION - MUST READ
- url: https://firebase.google.com/docs/ios/setup
  section: "Add Firebase to your iOS project"
  why: Complete Firebase iOS SDK integration including GoogleService-Info.plist setup
  critical: Bundle ID must match exactly (case-sensitive)

- url: https://firebase.google.com/docs/auth/ios/start
  section: "Email and password authentication"
  why: Core email/password authentication implementation patterns
  critical: Use modern async/await patterns, not completion handlers

- url: https://firebase.google.com/docs/auth/ios/errors
  section: "Handle authentication errors"
  why: Comprehensive error handling patterns and error code mapping
  critical: Implement user-friendly error messages for all auth error codes

- url: https://firebase.google.com/docs/auth/ios/google-signin
  section: "Authenticate using Google Sign-In on iOS"
  why: Google Sign-In integration patterns for future implementation
  critical: URL scheme configuration and GoogleService-Info.plist setup

- url: https://firebase.google.com/support/guides/security-checklist
  section: "Authentication security best practices"
  why: Security implementation guidelines and protection strategies
  critical: Never use UID for backend authentication, always use ID tokens

# SWIFTUI AUTHENTICATION PATTERNS - MUST READ
- url: https://developer.apple.com/documentation/swiftui/managing-user-interface-state
  section: "State management with @Observable"
  why: Modern SwiftUI state management for authentication (iOS 17+ pattern)
  critical: Migration from @StateObject to @Observable for better performance

- url: https://developer.apple.com/documentation/security/keychain_services
  section: "Storing keys in the keychain"
  why: Secure token storage implementation using Keychain Services
  critical: Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly for auth tokens

- url: https://developer.apple.com/documentation/localauthentication
  section: "Biometric authentication"
  why: Face ID/Touch ID integration for secure app access
  critical: Proper privacy description in Info.plist and fallback handling

# MODERN IOS DEVELOPMENT PATTERNS - MUST READ
- url: https://developer.apple.com/documentation/swift/concurrency
  section: "Swift concurrency and async/await"
  why: Modern async patterns for Firebase integration
  critical: Use async/await for all Firebase operations, avoid completion handlers

- url: https://developer.apple.com/documentation/swiftui/navigationstack
  section: "NavigationStack for iOS 16+"
  why: Modern navigation patterns replacing deprecated NavigationView
  critical: Use NavigationPath for programmatic navigation control
```

### Firebase Project Configuration (User-Provided)

**Reference File**: `Dependencies Config/Firebase` - Complete Firebase configuration details

```yaml
PROJECT_INFO:
  name: "Ios Voice Control"
  id: "ios-voice-control"
  number: "1020288809254"
  web_api_key: "AIzaSyDfPSiJnWv3Ww--87njC93SZxTjAcTsXoo"
  public_name: "project-1020288809254"
  email: "colin.mignot1@gmail.com"

IOS_APP:
  bundle_id: "com.voicecontrol.app"
  app_id: "1:1020288809254:ios:0f690b195cca167b47a9e7"
  encoded_app_id: "app-1-1020288809254-ios-0f690b195cca167b47a9e7"

FUTURE_INTEGRATIONS:
  - Apple Pay (requires Apple Developer account setup)
  - Google Sign-In (OAuth client configuration needed)
  - AssemblyAI (API key and secure storage required)
```

### Current Codebase Tree

```bash
PRPs-agentic-eng/
├── .claude/
│   ├── commands/           # 28+ Claude Code commands
│   └── settings.local.json # Firebase domains whitelisted
├── PRPs/
│   ├── templates/          # PRP templates
│   ├── scripts/           # PRP runner utilities
│   └── ai_docs/           # Claude Code documentation
├── claude_md_files/       # Framework-specific CLAUDE.md examples
├── pyproject.toml         # Python package configuration
├── CLAUDE.md             # Project guidelines
└── README.md             # Framework documentation

# NOTE: No iOS project exists yet - this will be created from scratch
```

### Desired iOS Project Structure

```bash
IosVoiceControl/
├── IosVoiceControl.xcodeproj
├── IosVoiceControl/
│   ├── App/
│   │   ├── IosVoiceControlApp.swift      # App entry point with Firebase config
│   │   ├── AppDelegate.swift             # Firebase initialization
│   │   └── ContentView.swift             # Root view with auth state routing
│   │
│   ├── Authentication/
│   │   ├── ViewModels/
│   │   │   ├── AuthenticationManager.swift    # @Observable auth state manager
│   │   │   └── BiometricAuthManager.swift     # Face ID/Touch ID management
│   │   ├── Views/
│   │   │   ├── AuthenticationView.swift       # Main auth container
│   │   │   ├── SignInView.swift              # Email/password sign in
│   │   │   ├── SignUpView.swift              # User registration
│   │   │   ├── PasswordResetView.swift       # Password reset flow
│   │   │   └── AccountManagementView.swift   # User account settings
│   │   ├── Models/
│   │   │   ├── User.swift                    # User data model
│   │   │   ├── AuthenticationError.swift     # Custom error types
│   │   │   └── AuthenticationState.swift     # Auth state enumeration
│   │   └── Services/
│   │       ├── FirebaseAuthService.swift     # Firebase auth operations
│   │       ├── KeychainService.swift         # Secure token storage
│   │       └── BiometricService.swift        # Biometric auth service
│   │
│   ├── Shared/
│   │   ├── Extensions/
│   │   │   ├── View+Extensions.swift         # SwiftUI view modifiers
│   │   │   └── Color+Extensions.swift        # App color scheme
│   │   ├── Components/
│   │   │   ├── LoadingButton.swift           # Reusable loading button
│   │   │   ├── SecureTextField.swift         # Custom secure text field
│   │   │   └── ErrorAlertModifier.swift      # Error display modifier
│   │   └── Utils/
│   │       ├── Constants.swift               # App constants
│   │       ├── Validation.swift              # Input validation utilities
│   │       └── NetworkMonitor.swift          # Network connectivity
│   │
│   ├── Resources/
│   │   ├── GoogleService-Info.plist          # Firebase configuration
│   │   ├── Info.plist                        # App configuration
│   │   └── Localizable.strings               # Localization strings
│   │
│   └── Supporting Files/
│       └── IosVoiceControl-Bridging-Header.h
│
├── IosVoiceControlTests/
│   ├── AuthenticationTests/
│   │   ├── AuthenticationManagerTests.swift
│   │   ├── FirebaseAuthServiceTests.swift
│   │   ├── KeychainServiceTests.swift
│   │   └── BiometricServiceTests.swift
│   ├── Mocks/
│   │   ├── MockFirebaseAuth.swift
│   │   └── MockKeychain.swift
│   └── TestHelpers/
│       └── XCTestCase+Extensions.swift
│
├── IosVoiceControlUITests/
│   ├── AuthenticationUITests.swift
│   ├── BiometricAuthUITests.swift
│   └── AccessibilityTests.swift
│
└── Package.swift                            # Swift Package Manager dependencies
```

### Known Gotchas & Critical Implementation Details

```swift
// CRITICAL: Firebase must be configured in AppDelegate, not App init()
// Use UIApplicationDelegateAdaptor for SwiftUI apps

// CRITICAL: Bundle ID in GoogleService-Info.plist must match Xcode exactly
// Case-sensitive matching - "com.voicecontrol.app" not "com.VoiceControl.app"

// CRITICAL: Use async/await, not completion handlers (modern pattern)
// OLD: Auth.auth().signIn(withEmail:password:completion:)
// NEW: try await Auth.auth().signIn(withEmail:password:)

// CRITICAL: Always update UI on main thread for auth state changes
// Use @MainActor or DispatchQueue.main.async for UI updates

// CRITICAL: Token validation - never use UID for backend auth
// CORRECT: user.getIDToken() for backend verification
// INCORRECT: user.uid for authentication (easily spoofed)

// CRITICAL: Keychain attribute for auth tokens
// Use kSecAttrAccessibleWhenUnlockedThisDeviceOnly (most secure)

// CRITICAL: NavigationStack (iOS 16+) replaces NavigationView
// Use NavigationPath for programmatic navigation

// CRITICAL: Error handling must be comprehensive
// Map all AuthErrorCode cases to user-friendly messages

// CRITICAL: @Observable (iOS 17+) replaces @StateObject for performance
// Migration: @StateObject → @Observable, @ObservedObject → no wrapper

// CRITICAL: Biometric auth requires Info.plist privacy descriptions:
// NSFaceIDUsageDescription for Face ID support
```

## Implementation Blueprint

### Data Models and Authentication Architecture

Create type-safe models for authentication state management:

```swift
// Authentication state management with @Observable pattern
@Observable
class AuthenticationManager {
    var authState: AuthState = .unauthenticated
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    
    enum AuthState {
        case unauthenticated
        case authenticating
        case authenticated
        case requiresBiometric
        case error(AuthenticationError)
    }
}

// Comprehensive error handling
enum AuthenticationError: Error, LocalizedError {
    case invalidCredential
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case tooManyRequests
    case userDisabled
    case biometricUnavailable
    case keychainError
    
    var errorDescription: String? {
        // User-friendly error messages
    }
}

// Secure user model
struct User: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    let isEmailVerified: Bool
    let creationDate: Date
    let lastSignInDate: Date
}
```

### List of Tasks to be Completed (Progressive Implementation)

```yaml
Task 1 - Create iOS Project and Firebase Setup:
CREATE new iOS project in Xcode:
  - Name: "IosVoiceControl"
  - Bundle ID: "com.voicecontrol.app" (EXACT match to Firebase)
  - Deployment Target: iOS 16.0 (for NavigationStack support)
  - Language: Swift
  - Interface: SwiftUI
  - Include tests: YES

DOWNLOAD GoogleService-Info.plist:
  - From Firebase Console → Project Settings → iOS App
  - Verify bundle ID matches exactly: "com.voicecontrol.app"
  - Drag to Xcode project root (Add to target: IosVoiceControl)

CONFIGURE Package.swift dependencies:
  - ADD Firebase iOS SDK via Swift Package Manager
  - URL: https://github.com/firebase/firebase-ios-sdk
  - Products: FirebaseAuth, FirebaseFirestore, FirebaseAnalytics
  - ADD GoogleSignIn SDK for future Google auth

Task 2 - Core Authentication Architecture:
CREATE IosVoiceControl/App/AppDelegate.swift:
  - IMPLEMENT UIApplicationDelegate for Firebase configuration
  - PATTERN: Configure Firebase in didFinishLaunchingWithOptions
  - IMPORT FirebaseCore and call FirebaseApp.configure()

CREATE IosVoiceControl/App/IosVoiceControlApp.swift:
  - USE @UIApplicationDelegateAdaptor for AppDelegate integration
  - CREATE @StateObject authManager for app-wide auth state
  - CONFIGURE app entry point with proper Firebase initialization

Task 3 - Authentication State Management:
CREATE Authentication/ViewModels/AuthenticationManager.swift:
  - IMPLEMENT @Observable pattern (iOS 17+ modern approach)
  - SETUP Auth.auth().addStateDidChangeListener for reactive updates
  - HANDLE user session persistence and token refresh
  - PATTERN: Use weak self to prevent retain cycles in listeners

CREATE Authentication/Models/AuthenticationState.swift:
  - DEFINE comprehensive auth state enumeration
  - INCLUDE loading states, error states, and success states
  - SUPPORT biometric authentication requirements

CREATE Authentication/Models/AuthenticationError.swift:
  - MAP all Firebase AuthErrorCode cases to user-friendly messages
  - IMPLEMENT LocalizedError for proper error display
  - INCLUDE network error handling and retry logic

Task 4 - Secure Storage Implementation:
CREATE Authentication/Services/KeychainService.swift:
  - IMPLEMENT secure token storage using Keychain Services
  - USE kSecAttrAccessibleWhenUnlockedThisDeviceOnly attribute
  - HANDLE keychain errors gracefully with proper fallbacks
  - PATTERN: Generic keychain wrapper for different data types

CREATE Authentication/Services/FirebaseAuthService.swift:
  - IMPLEMENT all Firebase authentication operations
  - USE async/await patterns instead of completion handlers
  - INCLUDE comprehensive error handling and mapping
  - HANDLE token refresh and session validation

Task 5 - Biometric Authentication:
CREATE Authentication/ViewModels/BiometricAuthManager.swift:
  - IMPLEMENT LocalAuthentication framework integration
  - SUPPORT Face ID and Touch ID with proper fallbacks
  - HANDLE biometric availability and enrollment status
  - PATTERN: Combine biometric auth with Firebase token validation

CREATE Authentication/Services/BiometricService.swift:
  - IMPLEMENT LAContext management and policy evaluation
  - HANDLE all biometric error cases (unavailable, locked out, canceled)
  - PROVIDE biometric capability detection
  - ENSURE thread-safe UI updates using @MainActor

Task 6 - Authentication User Interface:
CREATE Authentication/Views/AuthenticationView.swift:
  - IMPLEMENT main authentication container with state routing
  - USE NavigationStack for modern navigation patterns
  - HANDLE authentication state transitions smoothly
  - INCLUDE proper loading states and error display

CREATE Authentication/Views/SignInView.swift:
  - IMPLEMENT email/password sign-in with validation
  - USE SecureField for password input with proper styling
  - INCLUDE "Forgot Password" navigation and error handling
  - PATTERN: Follow Apple Human Interface Guidelines for forms

CREATE Authentication/Views/SignUpView.swift:
  - IMPLEMENT user registration with email verification
  - VALIDATE email format and password strength
  - INCLUDE terms of service and privacy policy links
  - HANDLE registration errors with user-friendly messaging

CREATE Authentication/Views/PasswordResetView.swift:
  - IMPLEMENT password reset email functionality
  - PROVIDE clear user feedback for reset email status
  - HANDLE invalid email errors and success messaging
  - INCLUDE navigation back to sign-in flow

Task 7 - Shared Components and Utilities:
CREATE Shared/Components/LoadingButton.swift:
  - IMPLEMENT reusable button with loading state
  - DISABLE user interaction during loading
  - INCLUDE haptic feedback for better UX
  - SUPPORT accessibility features

CREATE Shared/Components/SecureTextField.swift:
  - IMPLEMENT custom secure text field with show/hide password
  - INCLUDE proper accessibility labels and hints
  - HANDLE keyboard types and return key behavior
  - SUPPORT password strength indicators

CREATE Shared/Utils/Validation.swift:
  - IMPLEMENT input validation utilities
  - INCLUDE email format validation
  - IMPLEMENT password strength requirements
  - PROVIDE real-time validation feedback

Task 8 - App Integration and Navigation:
MODIFY IosVoiceControl/App/ContentView.swift:
  - IMPLEMENT authentication state-based navigation
  - ROUTE to authentication views when unauthenticated
  - ROUTE to main app views when authenticated
  - HANDLE biometric requirement states

CREATE Authentication/Views/AccountManagementView.swift:
  - IMPLEMENT user profile and account settings
  - INCLUDE password change functionality
  - PROVIDE account deletion with proper warnings
  - HANDLE email verification status display

Task 9 - Accessibility and Localization:
UPDATE Resources/Info.plist:
  - ADD NSFaceIDUsageDescription for biometric authentication
  - INCLUDE proper app permissions and configurations
  - SET minimum iOS deployment target to 16.0

CREATE Resources/Localizable.strings:
  - IMPLEMENT localization strings for all user-facing text
  - INCLUDE error messages, button labels, and instructions
  - SUPPORT accessibility descriptions and hints

Task 10 - Google Sign-In Preparation:
CONFIGURE GoogleService-Info.plist:
  - VERIFY OAuth client configuration for Google Sign-In
  - EXTRACT and configure URL schemes in Info.plist
  - PREPARE GIDConfiguration setup for future implementation

CREATE placeholder for Google Sign-In integration:
  - SETUP URL scheme handling in AppDelegate
  - PREPARE Google Sign-In button component
  - INCLUDE configuration validation
```

### Per Task Implementation Patterns

```swift
// Task 2 - AppDelegate Firebase Configuration Pattern
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // CRITICAL: Configure Firebase before any other Firebase calls
        FirebaseApp.configure()
        
        // PATTERN: Setup any additional Firebase services here
        // Future: Analytics.logEvent() configuration
        
        return true
    }
}

// Task 3 - Authentication Manager Pattern
@Observable
class AuthenticationManager {
    var authState: AuthState = .unauthenticated
    var currentUser: User?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        // CRITICAL: Use weak self to prevent retain cycles
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                // CRITICAL: Update UI on main thread
                self?.handleAuthStateChange(user)
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

// Task 4 - Keychain Service Pattern
class KeychainService {
    private static let service = "com.voicecontrol.app.tokens"
    
    static func save<T: Codable>(_ item: T, for key: String) throws {
        let data = try JSONEncoder().encode(item)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // CRITICAL: Most secure accessibility level
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // PATTERN: Delete existing item first, then add new one
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

// Task 5 - Biometric Authentication Pattern
@MainActor
class BiometricAuthManager: ObservableObject {
    @Published var biometricType: LABiometryType = .none
    @Published var isAvailable = false
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // PATTERN: Check availability before attempting authentication
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your account"
            )
            return success
        } catch {
            // PATTERN: Map LAError to custom error types
            throw mapLAError(error)
        }
    }
}
```

### Integration Points

```yaml
FIREBASE_CONFIGURATION:
  - GoogleService-Info.plist in project root
  - Bundle ID: "com.voicecontrol.app" (exact match)
  - Firebase project: "ios-voice-control"
  - Web API Key: "AIzaSyDfPSiJnWv3Ww--87njC93SZxTjAcTsXoo"

KEYCHAIN_INTEGRATION:
  - Service identifier: "com.voicecontrol.app.tokens"
  - Accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
  - Token storage for session persistence

NAVIGATION_INTEGRATION:
  - NavigationStack for iOS 16+ compatibility
  - NavigationPath for programmatic navigation
  - State-based routing between auth and main app

FUTURE_INTEGRATIONS:
  - Google Sign-In OAuth client ready
  - Apple Pay merchant ID preparation
  - AssemblyAI API key secure storage
  - Push notification token management
```

## Validation Loop

**📋 Complete Validation Strategy**: See `Validation Strategies/1 - iOS-Firebase-Auth-Validation-Strategy.md` for comprehensive 5-level autonomous validation framework with detailed commands, error recovery, and AI agent integration.

### Level 1: Syntax & Style

```bash
# Swift syntax and style validation
swiftlint --strict --path IosVoiceControl/
# Expected: No violations. Fix any style issues immediately.

# Swift compilation check
xcodebuild -project IosVoiceControl.xcodeproj -scheme IosVoiceControl -destination 'platform=iOS Simulator,name=iPhone 15' build
# Expected: Build succeeds. Fix any compilation errors.

# GoogleService-Info.plist validation
plutil -lint IosVoiceControl/Resources/GoogleService-Info.plist
# Expected: "OK" output. Verify plist structure is valid.

# Bundle ID verification
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" IosVoiceControl/Info.plist
# Expected: "com.voicecontrol.app" (exact match to Firebase)
```

### Level 2: Unit Tests

```swift
// Comprehensive unit tests for authentication components
class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    var mockFirebaseAuth: MockFirebaseAuth!
    
    override func setUp() {
        super.setUp()
        mockFirebaseAuth = MockFirebaseAuth()
        authManager = AuthenticationManager(firebaseAuth: mockFirebaseAuth)
    }
    
    func testSignInSuccess() async throws {
        // Test successful sign-in flow
        mockFirebaseAuth.mockUser = MockUser(uid: "test123", email: "test@example.com")
        
        try await authManager.signIn(email: "test@example.com", password: "password123")
        
        XCTAssertEqual(authManager.authState, .authenticated)
        XCTAssertNotNil(authManager.currentUser)
    }
    
    func testSignInInvalidCredentials() async {
        // Test invalid credentials handling
        mockFirebaseAuth.shouldThrow = AuthErrorCode.wrongPassword
        
        do {
            try await authManager.signIn(email: "test@example.com", password: "wrong")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(authManager.authState, .error(.wrongPassword))
        }
    }
}

class KeychainServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        // Clean up keychain items after each test
        try? KeychainService.deleteAll()
    }
    
    func testSaveAndRetrieveToken() throws {
        let token = "test-token-123"
        
        try KeychainService.save(token, for: "auth_token")
        let retrieved: String = try KeychainService.retrieve("auth_token")
        
        XCTAssertEqual(token, retrieved)
    }
}
```

```bash
# Run unit tests with coverage reporting
xcodebuild test -project IosVoiceControl.xcodeproj -scheme IosVoiceControl -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
# Expected: All tests pass with >90% coverage for authentication logic
```

### Level 3: Integration Testing with Firebase Emulator

```bash
# Start Firebase emulator for isolated testing
firebase emulators:start --only auth
# Expected: Auth emulator running on localhost:9099

# Run integration tests against emulator
xcodebuild test -project IosVoiceControl.xcodeproj -scheme IosVoiceControl -destination 'platform=iOS Simulator,name=iPhone 15' -testPlan IntegrationTests
# Expected: All integration tests pass against emulator

# Test authentication flows end-to-end
curl -X POST "http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=test-api-key" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123","returnSecureToken":true}'
# Expected: Successful user creation response
```

### Level 4: UI Testing and Accessibility

```swift
// Comprehensive UI tests for authentication flows
class AuthenticationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
    }
    
    func testSignInFlow() {
        // Test complete sign-in user journey
        app.textFields["EmailTextField"].tap()
        app.textFields["EmailTextField"].typeText("test@example.com")
        
        app.secureTextFields["PasswordTextField"].tap()
        app.secureTextFields["PasswordTextField"].typeText("password123")
        
        app.buttons["SignInButton"].tap()
        
        // Verify navigation to main app
        XCTAssertTrue(app.staticTexts["Welcome"].waitForExistence(timeout: 5))
    }
    
    func testAccessibility() {
        // Verify accessibility compliance
        XCTAssertTrue(app.textFields["EmailTextField"].isAccessibilityElement)
        XCTAssertTrue(app.secureTextFields["PasswordTextField"].isAccessibilityElement)
        XCTAssertNotNil(app.buttons["SignInButton"].accessibilityLabel)
    }
}
```

```bash
# Run UI tests with accessibility validation
xcodebuild test -project IosVoiceControl.xcodeproj -scheme IosVoiceControl -destination 'platform=iOS Simulator,name=iPhone 15' -testPlan UITests
# Expected: All UI tests pass with accessibility compliance

# Accessibility audit using Xcode Accessibility Inspector
# Manual verification: Run app with Accessibility Inspector enabled
# Expected: No accessibility violations reported
```

### Level 5: Security and Production Readiness

```bash
# Security analysis with MobSF (Mobile Security Framework)
docker run --rm -p 8000:8000 opensecurity/mobsf:latest
# Upload IPA file for comprehensive security analysis
# Expected: No critical security vulnerabilities

# Certificate pinning validation (for production)
# Verify SSL certificate pinning implementation
openssl s_client -connect firebase.googleapis.com:443 -servername firebase.googleapis.com
# Expected: Proper certificate chain validation

# Firebase security rules validation
firebase deploy --only firestore:rules
firebase firestore:rules:test --test-suite=security-tests/
# Expected: All security rules tests pass

# App Store preparation checklist
xcodebuild archive -project IosVoiceControl.xcodeproj -scheme IosVoiceControl -destination 'generic/platform=iOS' -archivePath IosVoiceControl.xcarchive
# Expected: Successful archive creation for App Store submission
```

## Final Validation Checklist

- [ ] All unit tests pass: `xcodebuild test` with >90% coverage
- [ ] No Swift compilation errors: `xcodebuild build` succeeds
- [ ] No SwiftLint violations: `swiftlint --strict` passes
- [ ] Firebase integration works: User registration and sign-in functional
- [ ] Keychain storage secure: Tokens persist across app launches
- [ ] Biometric authentication works: Face ID/Touch ID integration functional
- [ ] UI tests pass: Complete authentication flows tested
- [ ] Accessibility compliance: No violations in Accessibility Inspector
- [ ] Security analysis clean: MobSF scan shows no critical issues
- [ ] Error handling comprehensive: All error scenarios covered
- [ ] Firebase emulator tests pass: Integration tests with emulator
- [ ] Google Sign-In configured: Ready for future implementation
- [ ] Documentation complete: Code comments and README updated

---

## PRP Success Confidence Score: 9/10

**Rationale for High Confidence:**
- **Comprehensive Context**: Extensive Firebase and iOS documentation with specific URLs and sections
- **Progressive Implementation**: Clear task breakdown from setup to advanced features
- **Modern Patterns**: Uses latest SwiftUI @Observable patterns and iOS 16+ NavigationStack
- **Autonomous Validation**: 5-level validation strategy with executable commands
- **Security Focus**: Proper Keychain implementation and biometric authentication
- **Real Configuration**: User-provided Firebase project details for immediate implementation
- **Future-Proofed**: Prepared for Google Sign-In, Apple Pay, and AssemblyAI integration

**Areas for Potential Challenge:**
- First-time iOS project creation requires careful Xcode setup
- Firebase configuration dependencies require precise bundle ID matching

This PRP provides comprehensive context for one-pass implementation success with autonomous validation capabilities.