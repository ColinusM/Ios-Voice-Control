import Foundation

// MARK: - Subscription Status

/// Current subscription status of the user
enum SubscriptionStatus: String, CaseIterable, Codable {
    case free = "free"
    case trial = "trial"
    case premiumMonthly = "premium_monthly"
    case premiumYearly = "premium_yearly"
    case lifetime = "lifetime"
    
    /// Whether this status provides premium benefits
    var isPremium: Bool {
        switch self {
        case .free, .trial:
            return false
        case .premiumMonthly, .premiumYearly, .lifetime:
            return true
        }
    }
    
    /// User-friendly display name
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .trial:
            return "Free Trial"
        case .premiumMonthly:
            return "Premium Monthly"
        case .premiumYearly:
            return "Premium Yearly"
        case .lifetime:
            return "Lifetime Premium"
        }
    }
    
    /// Billing period in days (nil for one-time purchases)
    var billingPeriodDays: Int? {
        switch self {
        case .free, .lifetime:
            return nil
        case .trial:
            return 7
        case .premiumMonthly:
            return 30
        case .premiumYearly:
            return 365
        }
    }
    
    /// Price information for display
    var priceDescription: String {
        switch self {
        case .free:
            return "Free"
        case .trial:
            return "7-day free trial"
        case .premiumMonthly:
            return "$9.99/month"
        case .premiumYearly:
            return "$99.99/year"
        case .lifetime:
            return "$299.99 one-time"
        }
    }
    
    /// Status color for UI
    var statusColor: String {
        switch self {
        case .free:
            return "gray"
        case .trial:
            return "blue"
        case .premiumMonthly, .premiumYearly:
            return "green"
        case .lifetime:
            return "gold"
        }
    }
}