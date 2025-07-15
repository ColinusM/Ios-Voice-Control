import Foundation
import AuthenticationServices

// MARK: - Social Authentication Errors

/// Comprehensive error handling for social authentication flows
enum SocialAuthError: Error, LocalizedError, Equatable {
    
    // MARK: - Configuration Errors
    case providerConfigurationMissing(SocialAuthProvider)
    case invalidClientConfiguration(SocialAuthProvider)
    case missingGoogleServiceInfo
    case invalidBundleIdentifier
    
    // MARK: - User Interaction Errors
    case userCancelled(SocialAuthProvider)
    case userDeniedPermission(SocialAuthProvider)
    case authorizationFailed(SocialAuthProvider)
    
    // MARK: - Network and Communication Errors
    case networkError(underlying: Error)
    case serverError(statusCode: Int)
    case requestTimeout
    case invalidResponse
    
    // MARK: - Token and Credential Errors
    case tokenExchangeFailed(SocialAuthProvider)
    case tokenRefreshFailed(SocialAuthProvider)
    case invalidTokenFormat(SocialAuthProvider)
    case expiredCredentials(SocialAuthProvider)
    
    // MARK: - Provider-Specific Errors
    
    // Google-specific errors
    case googleSignInUnavailable
    case googleAccountAlreadyInUse
    case googleInvalidClientId
    
    // Apple-specific errors
    case appleSignInUnavailable
    case appleAccountNotFound
    case privacyRelayEmailUnsupported
    case appleIdCredentialInvalid
    case biometricAuthenticationRequired
    
    // MARK: - Firebase Integration Errors
    case firebaseCredentialCreationFailed(SocialAuthProvider)
    case firebaseSignInFailed(underlying: Error)
    case accountLinkingFailed(SocialAuthProvider)
    case existingAccountConflict(SocialAuthProvider)
    
    // MARK: - Device and Platform Errors
    case deviceNotSupported
    case iOSVersionTooOld
    case appNotAuthorized
    case keychainAccessFailed
    
    // MARK: - Generic Errors
    case unknown(underlying: Error?)
    case internalError(description: String)
    
    // MARK: - Error Descriptions
    
    var errorDescription: String? {
        switch self {
        // Configuration Errors
        case .providerConfigurationMissing(let provider):
            return "\(provider.displayName) Sign-In is not properly configured. Please contact support."
        case .invalidClientConfiguration(let provider):
            return "\(provider.displayName) configuration is invalid. Please update the app."
        case .missingGoogleServiceInfo:
            return "Google services configuration is missing. Please contact support."
        case .invalidBundleIdentifier:
            return "App configuration error. Please update the app."
            
        // User Interaction Errors
        case .userCancelled:
            return "Sign-in was cancelled. Please try again if you'd like to sign in."
        case .userDeniedPermission(let provider):
            return "Permission denied for \(provider.displayName) Sign-In. You can try again or use a different sign-in method."
        case .authorizationFailed(let provider):
            return "\(provider.displayName) authorization failed. Please try again."
            
        // Network Errors
        case .networkError:
            return "Network connection failed. Please check your internet connection and try again."
        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."
        case .requestTimeout:
            return "Request timed out. Please check your connection and try again."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
            
        // Token Errors
        case .tokenExchangeFailed(let provider):
            return "\(provider.displayName) authentication failed. Please try again."
        case .tokenRefreshFailed(let provider):
            return "\(provider.displayName) session expired. Please sign in again."
        case .invalidTokenFormat(let provider):
            return "\(provider.displayName) authentication error. Please try again."
        case .expiredCredentials(let provider):
            return "\(provider.displayName) session has expired. Please sign in again."
            
        // Google-specific
        case .googleSignInUnavailable:
            return "Google Sign-In is temporarily unavailable. Please try again later."
        case .googleAccountAlreadyInUse:
            return "This Google account is already linked to another user. Please use a different account."
        case .googleInvalidClientId:
            return "Google Sign-In configuration error. Please contact support."
            
        // Apple-specific
        case .appleSignInUnavailable:
            return "Sign in with Apple is not available. Please ensure you're signed in to iCloud."
        case .appleAccountNotFound:
            return "Apple ID not found. Please ensure you're signed in to iCloud."
        case .privacyRelayEmailUnsupported:
            return "This app doesn't support private relay emails. Please use your actual email address."
        case .appleIdCredentialInvalid:
            return "Invalid Apple ID credentials. Please try again."
        case .biometricAuthenticationRequired:
            return "Biometric authentication is required for Apple Sign-In on this device."
            
        // Firebase Integration
        case .firebaseCredentialCreationFailed(let provider):
            return "\(provider.displayName) authentication failed. Please try again."
        case .firebaseSignInFailed:
            return "Sign-in failed. Please try again."
        case .accountLinkingFailed(let provider):
            return "Failed to link \(provider.displayName) account. Please try again."
        case .existingAccountConflict(let provider):
            return "An account with this email already exists. Please sign in with your existing method or contact support."
            
        // Device/Platform
        case .deviceNotSupported:
            return "This feature is not supported on your device."
        case .iOSVersionTooOld:
            return "Please update to the latest iOS version to use this feature."
        case .appNotAuthorized:
            return "App is not authorized for this service. Please contact support."
        case .keychainAccessFailed:
            return "Failed to securely store credentials. Please try again."
            
        // Generic
        case .unknown:
            return "An unexpected error occurred. Please try again."
        case .internalError(let description):
            return "Internal error: \(description)"
        }
    }
    
    // MARK: - Error Recovery Suggestions
    
    var recoverySuggestion: String? {
        switch self {
        case .userCancelled:
            return "Tap the sign-in button again to continue."
        case .networkError, .requestTimeout:
            return "Check your internet connection and try again."
        case .tokenRefreshFailed, .expiredCredentials:
            return "Please sign in again to refresh your session."
        case .appleSignInUnavailable:
            return "Ensure you're signed in to iCloud in Settings > [Your Name]."
        case .googleSignInUnavailable:
            return "Try again in a few moments or use a different sign-in method."
        case .existingAccountConflict:
            return "Use your existing sign-in method or contact support for help."
        case .privacyRelayEmailUnsupported:
            return "Go to Settings > Apple ID > Sign-In & Security > Hide My Email and disable it for this app."
        default:
            return "Try again or contact support if the problem persists."
        }
    }
    
    // MARK: - Error Categories
    
    /// Returns true if this is a user-actionable error that should be displayed prominently
    var isUserActionable: Bool {
        switch self {
        case .userCancelled, .userDeniedPermission, .networkError, .requestTimeout,
             .appleSignInUnavailable, .existingAccountConflict, .privacyRelayEmailUnsupported:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this error should trigger an automatic retry
    var shouldRetry: Bool {
        switch self {
        case .networkError, .serverError, .requestTimeout, .invalidResponse:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this is a configuration or development error
    var isDeveloperError: Bool {
        switch self {
        case .providerConfigurationMissing, .invalidClientConfiguration, .missingGoogleServiceInfo,
             .invalidBundleIdentifier, .googleInvalidClientId, .appNotAuthorized:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Mapping Extensions

extension SocialAuthError {
    
    /// Creates a SocialAuthError from an ASAuthorizationError
    static func fromAppleAuthError(_ error: Error, provider: SocialAuthProvider = .apple) -> SocialAuthError {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                return .userCancelled(provider)
            case .failed:
                return .authorizationFailed(provider)
            case .invalidResponse:
                return .appleIdCredentialInvalid
            case .notHandled:
                return .appleSignInUnavailable
            case .notInteractive:
                return .biometricAuthenticationRequired
            case .unknown:
                return .unknown(underlying: error)
            @unknown default:
                return .unknown(underlying: error)
            }
        }
        return .unknown(underlying: error)
    }
    
    /// Creates a SocialAuthError from a general error
    static func fromError(_ error: Error, provider: SocialAuthProvider) -> SocialAuthError {
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(underlying: error)
            case .timedOut:
                return .requestTimeout
            default:
                return .networkError(underlying: error)
            }
        }
        
        // Check for Firebase Auth errors
        if let nsError = error as NSError?, nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17007: // Account exists with different credential
                return .existingAccountConflict(provider)
            case 17008: // Requires recent login
                return .tokenRefreshFailed(provider)
            case 17011: // User not found
                return .appleAccountNotFound
            default:
                return .firebaseSignInFailed(underlying: error)
            }
        }
        
        return .unknown(underlying: error)
    }
}

// MARK: - Integration with Existing AuthenticationError

extension AuthenticationError {
    
    /// Converts a SocialAuthError to the existing AuthenticationError system
    static func from(_ socialError: SocialAuthError) -> AuthenticationError {
        switch socialError {
        case .userCancelled:
            return .unknownError("User cancelled sign-in")
        case .networkError:
            return .networkError
        case .tokenRefreshFailed, .expiredCredentials:
            return .requiresRecentLogin
        case .existingAccountConflict:
            return .emailAlreadyInUse
        case .providerConfigurationMissing, .invalidClientConfiguration, .missingGoogleServiceInfo:
            return .operationNotAllowed
        case .firebaseSignInFailed(let underlying):
            return .fromFirebaseError(underlying)
        case .keychainAccessFailed:
            return .keychainError
        case .deviceNotSupported, .iOSVersionTooOld, .appNotAuthorized:
            return .operationNotAllowed
        default:
            return .unknownError(socialError.localizedDescription)
        }
    }
}