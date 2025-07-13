import Foundation
import FirebaseAuth

// MARK: - Comprehensive Authentication Error Handling

enum AuthenticationError: Error, LocalizedError, Equatable {
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
    case invalidEmail
    case operationNotAllowed
    case requiresRecentLogin
    case emailNotVerified
    case unknownError(String)
    
    // MARK: - User-Friendly Error Messages
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "The credentials provided are invalid. Please check your email and password."
        case .userNotFound:
            return "No account found with this email address. Please sign up or check your email."
        case .wrongPassword:
            return "Incorrect password. Please try again or reset your password."
        case .emailAlreadyInUse:
            return "An account already exists with this email address. Please sign in instead."
        case .weakPassword:
            return "Password is too weak. Please use at least 8 characters with a mix of letters and numbers."
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .tooManyRequests:
            return "Too many failed attempts. Please wait a few minutes before trying again."
        case .userDisabled:
            return "Your account has been disabled. Please contact support for assistance."
        case .biometricUnavailable:
            return "Biometric authentication is not available. Please use your password instead."
        case .keychainError:
            return "Secure storage error. Please restart the app and try again."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .operationNotAllowed:
            return "This operation is not allowed. Please contact support if the problem persists."
        case .requiresRecentLogin:
            return "This operation requires recent authentication. Please sign in again."
        case .emailNotVerified:
            return "Please verify your email address before continuing."
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credentials"
        case .userNotFound:
            return "User account not found"
        case .wrongPassword:
            return "Password verification failed"
        case .emailAlreadyInUse:
            return "Email address already registered"
        case .weakPassword:
            return "Password does not meet security requirements"
        case .networkError:
            return "Network connectivity issue"
        case .tooManyRequests:
            return "Rate limit exceeded"
        case .userDisabled:
            return "Account disabled by administrator"
        case .biometricUnavailable:
            return "Biometric authentication unavailable"
        case .keychainError:
            return "Secure storage access failed"
        case .invalidEmail:
            return "Email format validation failed"
        case .operationNotAllowed:
            return "Operation not permitted"
        case .requiresRecentLogin:
            return "Authentication session expired"
        case .emailNotVerified:
            return "Email verification required"
        case .unknownError:
            return "Unhandled error condition"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredential, .wrongPassword:
            return "Try signing in again or use the 'Forgot Password' option."
        case .userNotFound:
            return "Create a new account or verify the email address is correct."
        case .emailAlreadyInUse:
            return "Sign in with this email or use the 'Forgot Password' option."
        case .weakPassword:
            return "Create a stronger password with at least 8 characters, including letters and numbers."
        case .networkError:
            return "Check your internet connection and try again."
        case .tooManyRequests:
            return "Wait a few minutes before attempting to sign in again."
        case .userDisabled:
            return "Contact customer support for account reactivation."
        case .biometricUnavailable:
            return "Use password authentication or enable biometrics in device settings."
        case .keychainError:
            return "Restart the app or contact support if the issue persists."
        case .invalidEmail:
            return "Enter a valid email address in the format: example@domain.com"
        case .operationNotAllowed:
            return "This authentication method may not be enabled. Contact support."
        case .requiresRecentLogin:
            return "Sign out and sign in again to continue."
        case .emailNotVerified:
            return "Check your email and click the verification link."
        case .unknownError:
            return "Try again or contact support if the problem continues."
        }
    }
    
    // MARK: - Firebase Error Mapping
    
    static func fromFirebaseError(_ error: Error) -> AuthenticationError {
        guard let authError = error as NSError?,
              let authErrorCode = AuthErrorCode.Code(rawValue: authError.code) else {
            return .unknownError(error.localizedDescription)
        }
        
        switch authErrorCode {
        case .invalidCredential:
            return .invalidCredential
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        case .userDisabled:
            return .userDisabled
        case .invalidEmail:
            return .invalidEmail
        case .operationNotAllowed:
            return .operationNotAllowed
        case .requiresRecentLogin:
            return .requiresRecentLogin
        default:
            return .unknownError(authError.localizedDescription)
        }
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredential, .invalidCredential),
             (.userNotFound, .userNotFound),
             (.wrongPassword, .wrongPassword),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.weakPassword, .weakPassword),
             (.networkError, .networkError),
             (.tooManyRequests, .tooManyRequests),
             (.userDisabled, .userDisabled),
             (.biometricUnavailable, .biometricUnavailable),
             (.keychainError, .keychainError),
             (.invalidEmail, .invalidEmail),
             (.operationNotAllowed, .operationNotAllowed),
             (.requiresRecentLogin, .requiresRecentLogin),
             (.emailNotVerified, .emailNotVerified):
            return true
        case (.unknownError(let lhsMessage), .unknownError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}