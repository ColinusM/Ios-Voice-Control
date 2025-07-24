import Foundation

// MARK: - Authentication State Management

enum AuthState: Equatable {
    case unauthenticated
    case guest
    case authenticating
    case authenticated
    case requiresBiometric
    case error(AuthenticationError)
    
    // Equatable conformance for AuthenticationError
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated),
             (.guest, .guest),
             (.authenticating, .authenticating),
             (.authenticated, .authenticated),
             (.requiresBiometric, .requiresBiometric):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .authenticating = self {
            return true
        }
        return false
    }
    
    var requiresAuth: Bool {
        switch self {
        case .unauthenticated, .error, .requiresBiometric:
            return true
        case .guest, .authenticated, .authenticating:
            return false
        }
    }
    
    // MARK: - Guest Mode Support (Apple Guideline 2.1 Compliance)
    
    /// Whether the current auth state allows access to the main app
    /// Guest and authenticated users can access core functionality
    var allowsAppAccess: Bool {
        switch self {
        case .guest, .authenticated:
            return true  // Both can access main app (Apple Guideline 2.1 compliance)
        default:
            return false
        }
    }
    
    /// Whether the user is in guest mode
    var isGuest: Bool {
        if case .guest = self {
            return true
        }
        return false
    }
}