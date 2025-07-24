import Foundation
import StoreKit

// MARK: - Subscription State Management

enum SubscriptionState: Equatable {
    case unknown
    case loading
    case free(remainingMinutes: Int)  // Minutes of API usage remaining (max 60) 
    case premium(expirationDate: Date?)
    case expired
    case error(SubscriptionError)
    
    // Equatable conformance for SubscriptionError
    static func == (lhs: SubscriptionState, rhs: SubscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.loading, .loading),
             (.expired, .expired):
            return true
        case (.free(let lhsMinutes), .free(let rhsMinutes)):
            return lhsMinutes == rhsMinutes
        case (.premium(let lhsDate), .premium(let rhsDate)):
            return lhsDate == rhsDate
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the user can access the AssemblyAI API ($0.17/hour)
    /// Premium users have unlimited access, free users have limited minutes
    var canAccessAPI: Bool {
        switch self {
        case .premium:
            return true  // Unlimited access for premium subscribers
        case .free(let minutes):
            return minutes > 0  // Has remaining free minutes (out of 60)
        default:
            return false  // Unknown, loading, expired, or error states
        }
    }
    
    /// Usage warning level based on remaining free minutes
    var usageWarningLevel: UsageWarningLevel {
        switch self {
        case .free(let minutes) where minutes <= 6:  // 10% remaining (6 minutes)
            return .critical
        case .free(let minutes) where minutes <= 15: // 25% remaining (15 minutes)
            return .warning  
        default:
            return .none
        }
    }
    
    /// Whether this is a premium subscription state
    var isPremium: Bool {
        if case .premium = self {
            return true
        }
        return false
    }
    
    /// Whether this is a free tier state
    var isFree: Bool {
        if case .free = self {
            return true
        }
        return false
    }
    
    /// Whether the subscription is in a loading state
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    /// Whether the subscription is expired
    var isExpired: Bool {
        switch self {
        case .expired:
            return true
        case .premium(let expirationDate):
            if let expDate = expirationDate {
                return expDate <= Date()
            }
            return false
        default:
            return false
        }
    }
    
    /// Display text for the current subscription state
    var displayText: String {
        switch self {
        case .unknown:
            return "Checking subscription..."
        case .loading:
            return "Loading..."
        case .free(let minutes):
            if minutes == 0 {
                return "No free time remaining"
            } else if minutes == 1 {
                return "1 minute remaining"
            } else {
                return "\(minutes) minutes remaining"
            }
        case .premium(let expirationDate):
            if let expDate = expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Premium until \(formatter.string(from: expDate))"
            } else {
                return "Premium subscription active"
            }
        case .expired:
            return "Subscription expired"
        case .error(let subscriptionError):
            return "Error: \(subscriptionError.localizedDescription)"
        }
    }
    
    /// Status icon for the current subscription state
    var statusIcon: String {
        switch self {
        case .unknown, .loading:
            return "ellipsis.circle"
        case .free:
            return "clock"
        case .premium:
            return "crown.fill"
        case .expired:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
    
    /// Whether to show upgrade prompts
    var shouldShowUpgradePrompt: Bool {
        switch self {
        case .free(let minutes) where minutes <= 15: // 25% remaining
            return true
        case .expired, .error:
            return true
        default:
            return false
        }
    }
}


// MARK: - Transaction Status

enum TransactionStatus: String, CaseIterable {
    case pending = "pending"
    case purchasing = "purchasing"
    case purchased = "purchased"
    case failed = "failed"
    case deferred = "deferred"
    case cancelled = "cancelled"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Processing..."
        case .purchasing:
            return "Purchasing..."
        case .purchased:
            return "Purchase Complete"
        case .failed:
            return "Purchase Failed"
        case .deferred:
            return "Purchase Deferred"
        case .cancelled:
            return "Purchase Cancelled"
        }
    }
    
    var isSuccessful: Bool {
        return self == .purchased
    }
    
    var isInProgress: Bool {
        return self == .pending || self == .purchasing
    }
    
    var requiresAction: Bool {
        return self == .failed || self == .deferred
    }
}

// MARK: - Subscription State Extensions

extension SubscriptionState {
    
    /// Creates a subscription state from remaining API minutes
    static func freeState(from guestUser: GuestUser?) -> SubscriptionState {
        guard let guest = guestUser else {
            return .free(remainingMinutes: 60) // Default 1 hour free
        }
        return .free(remainingMinutes: guest.remainingFreeMinutes)
    }
    
    /// Creates a premium state from StoreKit transaction
    static func premiumState(from transaction: Transaction?) -> SubscriptionState {
        guard let transaction = transaction else {
            return .expired
        }
        
        // Check if transaction is still valid
        if let expirationDate = transaction.expirationDate {
            if expirationDate <= Date() {
                return .expired
            }
            return .premium(expirationDate: expirationDate)
        }
        
        // Non-expiring subscription or lifetime purchase
        return .premium(expirationDate: nil)
    }
    
    /// Creates an error state from StoreKit or service errors
    static func errorState(from error: Error) -> SubscriptionState {
        if let subscriptionError = error as? SubscriptionError {
            return .error(subscriptionError)
        } else {
            return .error(.unknown(underlying: error))
        }
    }
}

// MARK: - Debug Description

extension SubscriptionState: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown:
            return "SubscriptionState.unknown"
        case .loading:
            return "SubscriptionState.loading"
        case .free(let minutes):
            return "SubscriptionState.free(remainingMinutes: \(minutes))"
        case .premium(let expirationDate):
            if let expDate = expirationDate {
                return "SubscriptionState.premium(expirationDate: \(expDate))"
            } else {
                return "SubscriptionState.premium(expirationDate: nil)"
            }
        case .expired:
            return "SubscriptionState.expired"
        case .error(let subscriptionError):
            return "SubscriptionState.error(\(subscriptionError))"
        }
    }
}