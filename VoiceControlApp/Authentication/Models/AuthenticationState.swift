import Foundation

// MARK: - Authentication State Management

enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated
    case requiresBiometric
    case error(AuthenticationError)
    
    // Equatable conformance for AuthenticationError
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated),
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
        case .authenticated, .authenticating:
            return false
        }
    }
}