import Foundation

// MARK: - Paywall Data

/// Data structure for presenting premium upgrade paywalls
struct PaywallData {
    let triggeredByFeature: PremiumFeature
    let userStatus: SubscriptionStatus
    let remainingTrialUsage: Int
    let trialPeriodDays: Int
    let monthlyPrice: Double
    let yearlyPrice: Double
    let yearlyDiscountPercent: Int
    
    /// Whether to show trial offer
    var shouldShowTrial: Bool {
        return userStatus == .free && remainingTrialUsage > 0
    }
    
    /// Yearly savings amount
    var yearlySavings: Double {
        return (monthlyPrice * 12) - yearlyPrice
    }
    
    /// Monthly equivalent price for yearly plan
    var yearlyMonthlyEquivalent: Double {
        return yearlyPrice / 12
    }
    
    /// Primary call-to-action text
    var primaryCTAText: String {
        if shouldShowTrial {
            return "Start \(trialPeriodDays)-Day Free Trial"
        } else {
            return "Upgrade to Premium"
        }
    }
    
    /// Secondary call-to-action text
    var secondaryCTAText: String {
        if shouldShowTrial {
            return "Continue with Limited Access"
        } else {
            return "Maybe Later"
        }
    }
    
    /// Feature-specific messaging
    var featureMessage: String {
        return "Upgrade to unlock \(triggeredByFeature.displayName) and all premium features"
    }
    
    /// Detailed benefit description
    var benefitsDescription: String {
        return """
        Premium includes:
        • \(PremiumFeature.cloudSync.displayName) - \(PremiumFeature.cloudSync.description)
        • \(PremiumFeature.advancedAnalytics.displayName) - \(PremiumFeature.advancedAnalytics.description)
        • \(PremiumFeature.customCommands.displayName) - \(PremiumFeature.customCommands.description)
        • \(PremiumFeature.prioritySupport.displayName) - \(PremiumFeature.prioritySupport.description)
        """
    }
    
    /// Trial usage summary
    var trialUsageSummary: String {
        if remainingTrialUsage > 0 {
            return "You have \(remainingTrialUsage) free uses remaining for \(triggeredByFeature.displayName)"
        } else {
            return "You've used all free attempts for \(triggeredByFeature.displayName)"
        }
    }
    
    /// Discount percentage for yearly plan
    var yearlyDiscountText: String {
        return "Save \(yearlyDiscountPercent)% with yearly billing"
    }
    
    /// Price comparison text
    var priceComparisonText: String {
        return String(format: "$%.2f/month vs $%.2f/month billed yearly", monthlyPrice, yearlyMonthlyEquivalent)
    }
}

// MARK: - Paywall Presentation Context

/// Context for when and how to present paywall
enum PaywallPresentationContext {
    case featureBlocked(PremiumFeature)
    case trialExpired(PremiumFeature)
    case upgradePrompt
    case onboarding
    
    var analyticsEvent: String {
        switch self {
        case .featureBlocked(let feature):
            return "paywall_feature_blocked_\(feature.rawValue)"
        case .trialExpired(let feature):
            return "paywall_trial_expired_\(feature.rawValue)"
        case .upgradePrompt:
            return "paywall_upgrade_prompt"
        case .onboarding:
            return "paywall_onboarding"
        }
    }
}