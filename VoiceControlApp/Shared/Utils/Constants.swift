import Foundation

// MARK: - App Constants

struct Constants {
    
    // MARK: - App Information
    
    struct App {
        static let name = "Voice Control"
        static let bundleIdentifier = "com.voicecontrol.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Voice Control"
    }
    
    // MARK: - Firebase Configuration
    
    struct Firebase {
        static let projectId = "ios-voice-control"
        static let webApiKey = "AIzaSyDfPSiJnWv3Ww--87njC93SZxTjAcTsXoo"
        static let projectNumber = "1020288809254"
        static let googleAppId = "1:1020288809254:ios:0f690b195cca167b47a9e7"
        static let reversedClientId = "com.googleusercontent.apps.1020288809254-0f690b195cca167b47a9e7"
    }
    
    // MARK: - Authentication
    
    struct Auth {
        
        // Keychain Configuration
        struct Keychain {
            static let service = "com.voicecontrol.app.tokens"
            static let userKey = "current_user"
            static let idTokenKey = "firebase_id_token"
            static let refreshTokenKey = "firebase_refresh_token"
            static let biometricTokenKey = "biometric_token"
        }
        
        // User Defaults Keys
        struct UserDefaults {
            static let biometricAuthEnabled = "biometric_auth_enabled"
            static let biometricPromptCount = "biometric_prompt_count"
            static let lastBiometricUse = "last_biometric_use"
            static let savedEmail = "saved_email"
            static let onboardingCompleted = "onboarding_completed"
            static let firstLaunch = "first_launch"
        }
        
        // Password Requirements
        struct Password {
            static let minLength = 8
            static let maxLength = 128
            static let requireUppercase = true
            static let requireLowercase = true
            static let requireNumbers = true
            static let requireSpecialCharacters = true
            static let minStrengthScore = 3 // Out of 5
        }
        
        // Session Management
        struct Session {
            static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes
            static let maxIdleTime: TimeInterval = 1800 // 30 minutes
            static let rememberMeDuration: TimeInterval = 2592000 // 30 days
        }
        
        // Biometric Authentication
        struct Biometric {
            static let maxPromptCount = 3
            static let reauthenticationInterval: TimeInterval = 300 // 5 minutes
            static let fallbackTitle = "Use Passcode"
            static let reason = "Authenticate to access your account securely"
        }
    }
    
    // MARK: - UI Configuration
    
    struct UI {
        
        // Animation Durations
        struct Animation {
            static let short: TimeInterval = 0.2
            static let medium: TimeInterval = 0.3
            static let long: TimeInterval = 0.5
            static let spring = 0.6
        }
        
        // Corner Radius
        struct CornerRadius {
            static let small: CGFloat = 8
            static let medium: CGFloat = 12
            static let large: CGFloat = 16
            static let xLarge: CGFloat = 20
        }
        
        // Padding
        struct Padding {
            static let xSmall: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let xLarge: CGFloat = 32
        }
        
        // Font Sizes
        struct FontSize {
            static let caption: CGFloat = 12
            static let body: CGFloat = 16
            static let title: CGFloat = 20
            static let largeTitle: CGFloat = 34
        }
        
        // Button Heights
        struct ButtonHeight {
            static let small: CGFloat = 36
            static let medium: CGFloat = 50
            static let large: CGFloat = 56
        }
        
        // Loading
        struct Loading {
            static let minDisplayTime: TimeInterval = 0.5
            static let timeout: TimeInterval = 30.0
        }
    }
    
    // MARK: - Network Configuration
    
    struct Network {
        static let timeoutInterval: TimeInterval = 30.0
        static let retryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        
        // URLs
        struct URLs {
            static let support = "https://support.voicecontrol.app"
            static let privacy = "https://voicecontrol.app/privacy"
            static let terms = "https://voicecontrol.app/terms"
            static let help = "https://help.voicecontrol.app"
            static let feedback = "mailto:feedback@voicecontrol.app"
            static let contactSupport = "mailto:support@voicecontrol.app"
        }
        
        // Firebase URLs
        struct Firebase {
            static let authEmulator = "localhost:9099"
            static let firestoreEmulator = "localhost:8080"
            static let functionsEmulator = "localhost:5001"
        }
    }
    
    // MARK: - Validation
    
    struct Validation {
        
        // Email
        struct Email {
            static let regex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
            static let maxLength = 254
        }
        
        // Name
        struct Name {
            static let minLength = 2
            static let maxLength = 50
            static let regex = #"^[a-zA-Z\s'\-]+$"#
        }
        
        // Phone
        struct Phone {
            static let minDigits = 10
            static let maxDigits = 15
        }
    }
    
    // MARK: - Accessibility
    
    struct Accessibility {
        
        // Identifiers
        struct Identifiers {
            static let emailTextField = "emailTextField"
            static let passwordTextField = "passwordTextField"
            static let confirmPasswordTextField = "confirmPasswordTextField"
            static let signInButton = "signInButton"
            static let signUpButton = "signUpButton"
            static let biometricAuthButton = "biometricAuthButton"
            static let resetPasswordButton = "resetPasswordButton"
        }
        
        // Labels
        struct Labels {
            static let passwordField = "Password field"
            static let emailField = "Email field"
            static let signInForm = "Sign in form"
            static let signUpForm = "Sign up form"
            static let biometricAuth = "Biometric authentication"
        }
        
        // Hints
        struct Hints {
            static let emailField = "Enter your email address"
            static let passwordField = "Enter your password securely"
            static let newPasswordField = "Create a secure password with at least 8 characters"
            static let confirmPasswordField = "Re-enter your password to confirm"
            static let signInButton = "Tap to sign in with your email and password"
            static let signUpButton = "Tap to create your new account"
            static let biometricButton = "Use Face ID or Touch ID to sign in"
        }
    }
    
    // MARK: - Testing
    
    struct Testing {
        static let isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        static let isUnitTesting = NSClassFromString("XCTestCase") != nil
        static let mockDelay: TimeInterval = 0.5
        
        // Test User Credentials
        struct TestCredentials {
            static let email = "test@example.com"
            static let password = "TestPassword123!"
            static let displayName = "Test User"
        }
    }
    
    // MARK: - Feature Flags
    
    struct FeatureFlags {
        static let biometricAuthEnabled = true
        static let googleSignInEnabled = false // Future implementation
        static let applePayEnabled = false // Future implementation
        static let pushNotificationsEnabled = false // Future implementation
        static let analyticsEnabled = false
        static let crashReportingEnabled = true
    }
    
    // MARK: - Error Messages
    
    struct ErrorMessages {
        static let genericError = "An unexpected error occurred. Please try again."
        static let networkError = "Please check your internet connection and try again."
        static let authenticationFailed = "Authentication failed. Please check your credentials."
        static let biometricUnavailable = "Biometric authentication is not available on this device."
        static let sessionExpired = "Your session has expired. Please sign in again."
        static let unknownError = "An unknown error occurred. Please contact support if this continues."
    }
    
    // MARK: - Success Messages
    
    struct SuccessMessages {
        static let accountCreated = "Account created successfully! Please check your email to verify your account."
        static let passwordReset = "Password reset email sent successfully!"
        static let emailVerified = "Email verified successfully!"
        static let profileUpdated = "Profile updated successfully!"
        static let passwordChanged = "Password changed successfully!"
    }
    
    // MARK: - Analytics Events
    
    struct Analytics {
        
        // Authentication Events
        struct Auth {
            static let signInAttempt = "auth_sign_in_attempt"
            static let signInSuccess = "auth_sign_in_success"
            static let signInFailure = "auth_sign_in_failure"
            static let signUpAttempt = "auth_sign_up_attempt"
            static let signUpSuccess = "auth_sign_up_success"
            static let signUpFailure = "auth_sign_up_failure"
            static let signOut = "auth_sign_out"
            static let passwordReset = "auth_password_reset"
            static let biometricAuth = "auth_biometric_attempt"
            static let biometricSuccess = "auth_biometric_success"
            static let biometricFailure = "auth_biometric_failure"
        }
        
        // App Events
        struct App {
            static let launch = "app_launch"
            static let foreground = "app_foreground"
            static let background = "app_background"
            static let crash = "app_crash"
        }
    }
}

// MARK: - Environment Helper

extension Constants {
    
    /// Returns true if running in debug mode
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Returns true if running in simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Returns the current environment name
    static var environment: String {
        if isDebug {
            return "Development"
        } else {
            return "Production"
        }
    }
    
    /// Returns true if running unit tests
    static var isRunningTests: Bool {
        return Testing.isUnitTesting || Testing.isUITesting
    }
}