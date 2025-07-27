import Foundation
import SwiftUI

// MARK: - Premium Feature Gate Service

/// Service responsible for managing premium feature access and enforcement
@MainActor
class PremiumFeatureGate: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current premium usage tracking
    @Published var usageTracker: PremiumUsageTracker
    
    /// Current subscription status
    @Published var subscriptionStatus: SubscriptionStatus
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    init(subscriptionStatus: SubscriptionStatus = .free) {
        self.subscriptionStatus = subscriptionStatus
        self.usageTracker = PremiumUsageTracker()
        loadPersistedData()
    }
    
    // MARK: - Feature Access Control
    
    /// Check if user can access a premium feature
    /// - Parameter feature: The premium feature to check
    /// - Returns: True if user has access, false otherwise
    func canAccess(_ feature: PremiumFeature) -> Bool {
        // Premium users have access to all features
        if subscriptionStatus.isPremium {
            return true
        }
        
        // Free users can access non-premium features
        if !feature.requiresPremium {
            return true
        }
        
        // Check free trial limits for premium features
        return hasRemainingTrialUsage(for: feature)
    }
    
    /// Get remaining free trial usage for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: Remaining free usage count
    func getRemainingTrialUsage(for feature: PremiumFeature) -> Int {
        let currentUsage = usageTracker.getUsage(for: feature)
        let freeLimit = feature.freeTrialLimit
        return max(0, freeLimit - currentUsage)
    }
    
    /// Track usage of a premium feature
    /// - Parameters:
    ///   - feature: The feature being used
    ///   - amount: The amount of usage (default: 1)
    /// - Returns: True if usage was successfully tracked
    @discardableResult
    func trackUsage(of feature: PremiumFeature, amount: Int = 1) -> Bool {
        // Always allow tracking for premium users
        guard !subscriptionStatus.isPremium else {
            return true
        }
        
        // Check if user has remaining trial usage
        guard hasRemainingTrialUsage(for: feature) else {
            return false
        }
        
        // Track the usage
        usageTracker.trackUsage(feature: feature, amount: amount)
        savePersistedData()
        
        #if DEBUG
        print("📊 Feature usage tracked: \(feature.displayName) (+\(amount))")
        print("   Remaining: \(getRemainingTrialUsage(for: feature))")
        #endif
        
        return true
    }
    
    /// Update subscription status
    /// - Parameter status: New subscription status
    func updateSubscription(_ status: SubscriptionStatus) {
        let wasFreeTier = !subscriptionStatus.isPremium
        subscriptionStatus = status
        
        // Reset usage tracking when upgrading to premium
        if wasFreeTier && status.isPremium {
            usageTracker.resetForNewBillingPeriod()
        }
        
        savePersistedData()
        
        #if DEBUG
        print("💳 Subscription updated: \(status.displayName)")
        #endif
    }
    
    // MARK: - Feature Gate Enforcement
    
    /// Attempt to use a premium feature with automatic gating
    /// - Parameters:
    ///   - feature: The feature to use
    ///   - action: The action to perform if access is granted
    /// - Returns: Result with success or gating information
    func useFeature<T>(
        _ feature: PremiumFeature,
        action: () throws -> T
    ) -> FeatureAccessResult<T> {
        
        // Check access
        guard canAccess(feature) else {
            return .blocked(createPaywallData(for: feature))
        }
        
        // Track usage (only for premium features)
        if feature.requiresPremium {
            trackUsage(of: feature)
        }
        
        // Execute action
        do {
            let result = try action()
            return .granted(result)
        } catch {
            return .error(error)
        }
    }
    
    /// Async version of feature usage
    /// - Parameters:
    ///   - feature: The feature to use
    ///   - action: The async action to perform if access is granted
    /// - Returns: Result with success or gating information
    func useFeature<T>(
        _ feature: PremiumFeature,
        action: () async throws -> T
    ) async -> FeatureAccessResult<T> {
        
        // Check access
        guard canAccess(feature) else {
            return .blocked(createPaywallData(for: feature))
        }
        
        // Track usage (only for premium features)
        if feature.requiresPremium {
            trackUsage(of: feature)
        }
        
        // Execute action
        do {
            let result = try await action()
            return .granted(result)
        } catch {
            return .error(error)
        }
    }
    
    // MARK: - Paywall Management
    
    /// Create paywall data for a blocked feature
    /// - Parameter feature: The feature that was blocked
    /// - Returns: Paywall data for presentation
    func createPaywallData(for feature: PremiumFeature) -> PaywallData {
        return PaywallData(
            triggeredByFeature: feature,
            userStatus: subscriptionStatus,
            remainingTrialUsage: getRemainingTrialUsage(for: feature),
            trialPeriodDays: 7,
            monthlyPrice: 9.99,
            yearlyPrice: 99.99,
            yearlyDiscountPercent: 17
        )
    }
    
    // MARK: - Usage Analytics
    
    /// Get usage summary for all features
    /// - Returns: Dictionary of feature usage
    func getUsageSummary() -> [PremiumFeature: Int] {
        var summary: [PremiumFeature: Int] = [:]
        
        for feature in PremiumFeature.allCases {
            summary[feature] = usageTracker.getUsage(for: feature)
        }
        
        return summary
    }
    
    /// Check if user is approaching trial limits
    /// - Returns: Features that are close to trial limit
    func getFeaturesNearLimit(threshold: Double = 0.8) -> [PremiumFeature] {
        return PremiumFeature.allCases.compactMap { feature in
            guard feature.requiresPremium else { return nil }
            
            let usage = usageTracker.getUsage(for: feature)
            let limit = feature.freeTrialLimit
            let usageRatio = Double(usage) / Double(limit)
            
            return usageRatio >= threshold ? feature : nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Check if user has remaining trial usage for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: True if trial usage remains
    private func hasRemainingTrialUsage(for feature: PremiumFeature) -> Bool {
        return getRemainingTrialUsage(for: feature) > 0
    }
    
    /// Load persisted usage and subscription data
    private func loadPersistedData() {
        // Load usage tracker
        if let data = userDefaults.data(forKey: "premium_usage_tracker"),
           let tracker = try? JSONDecoder().decode(PremiumUsageTracker.self, from: data) {
            usageTracker = tracker
        }
        
        // Load subscription status
        if let statusRaw = userDefaults.string(forKey: "subscription_status"),
           let status = SubscriptionStatus(rawValue: statusRaw) {
            subscriptionStatus = status
        }
    }
    
    /// Save usage and subscription data to persistence
    private func savePersistedData() {
        // Save usage tracker
        if let data = try? JSONEncoder().encode(usageTracker) {
            userDefaults.set(data, forKey: "premium_usage_tracker")
        }
        
        // Save subscription status
        userDefaults.set(subscriptionStatus.rawValue, forKey: "subscription_status")
    }
}

// MARK: - Feature Access Result

/// Result of attempting to use a premium feature
enum FeatureAccessResult<T> {
    case granted(T)                    // Access granted, result returned
    case blocked(PaywallData)          // Access blocked, show paywall
    case error(Error)                  // Error occurred during execution
    
    /// Whether access was granted
    var wasGranted: Bool {
        if case .granted = self {
            return true
        }
        return false
    }
    
    /// Get the result if access was granted
    var result: T? {
        if case .granted(let value) = self {
            return value
        }
        return nil
    }
    
    /// Get paywall data if access was blocked
    var paywallData: PaywallData? {
        if case .blocked(let data) = self {
            return data
        }
        return nil
    }
}

// MARK: - Singleton Access

extension PremiumFeatureGate {
    /// Shared feature gate instance
    static let shared = PremiumFeatureGate()
}