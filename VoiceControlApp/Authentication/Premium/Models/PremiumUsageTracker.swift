import Foundation

// MARK: - Premium Usage Tracker

/// Tracks usage of premium features for freemium model
struct PremiumUsageTracker: Codable {
    private var usage: [String: Int] = [:]
    private var lastResetDate: Date = Date()
    
    // MARK: - Usage Tracking
    
    /// Track usage of a feature
    /// - Parameters:
    ///   - feature: The feature being used
    ///   - amount: The amount to add to usage count (default: 1)
    mutating func trackUsage(feature: PremiumFeature, amount: Int = 1) {
        let key = feature.rawValue
        usage[key, default: 0] += amount
        
        #if DEBUG
        print("📊 Usage tracked: \(feature.displayName) (+\(amount)) = \(usage[key, default: 0])")
        #endif
    }
    
    /// Get current usage for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: Current usage count
    func getUsage(for feature: PremiumFeature) -> Int {
        return usage[feature.rawValue, default: 0]
    }
    
    /// Get remaining usage for a feature
    /// - Parameter feature: The feature to check
    /// - Returns: Remaining usage count before hitting limit
    func getRemainingUsage(for feature: PremiumFeature) -> Int {
        let currentUsage = getUsage(for: feature)
        let limit = feature.freeTrialLimit
        return max(0, limit - currentUsage)
    }
    
    /// Check if feature usage is available
    /// - Parameter feature: The feature to check
    /// - Returns: True if usage is still available
    func hasUsageRemaining(for feature: PremiumFeature) -> Bool {
        return getRemainingUsage(for: feature) > 0
    }
    
    /// Get usage percentage for a feature (0.0 - 1.0)
    /// - Parameter feature: The feature to check
    /// - Returns: Usage percentage
    func getUsagePercentage(for feature: PremiumFeature) -> Double {
        let currentUsage = getUsage(for: feature)
        let limit = feature.freeTrialLimit
        
        guard limit > 0 && limit != Int.max else { return 0.0 }
        
        return min(1.0, Double(currentUsage) / Double(limit))
    }
    
    // MARK: - Billing Period Management
    
    /// Reset usage tracking for new billing period
    mutating func resetForNewBillingPeriod() {
        usage.removeAll()
        lastResetDate = Date()
        
        #if DEBUG
        print("📊 Usage tracker reset for new billing period")
        #endif
    }
    
    /// Check if usage should be reset (monthly cycle)
    /// - Returns: True if reset is needed
    func shouldResetUsage() -> Bool {
        let calendar = Calendar.current
        let daysSinceReset = calendar.dateComponents([.day], from: lastResetDate, to: Date()).day ?? 0
        return daysSinceReset >= 30 // Monthly reset cycle
    }
    
    /// Reset usage if monthly cycle has passed
    /// - Returns: True if reset was performed
    mutating func resetIfNeeded() -> Bool {
        if shouldResetUsage() {
            resetForNewBillingPeriod()
            return true
        }
        return false
    }
    
    // MARK: - Analytics & Reporting
    
    /// Get total usage across all features
    var totalUsage: Int {
        return usage.values.reduce(0, +)
    }
    
    /// Get usage summary for all features
    var usageSummary: [PremiumFeature: Int] {
        var summary: [PremiumFeature: Int] = [:]
        
        for feature in PremiumFeature.allCases {
            summary[feature] = getUsage(for: feature)
        }
        
        return summary
    }
    
    /// Get features that are approaching their limits
    /// - Parameter threshold: Percentage threshold (0.0 - 1.0)
    /// - Returns: Features approaching limit
    func getFeaturesNearLimit(threshold: Double = 0.8) -> [PremiumFeature] {
        return PremiumFeature.allCases.filter { feature in
            guard feature.requiresPremium else { return false }
            return getUsagePercentage(for: feature) >= threshold
        }
    }
    
    /// Get features that have exceeded their limits
    /// - Returns: Features that have no remaining usage
    func getFeaturesAtLimit() -> [PremiumFeature] {
        return PremiumFeature.allCases.filter { feature in
            guard feature.requiresPremium else { return false }
            return !hasUsageRemaining(for: feature)
        }
    }
    
    /// Get most used features
    /// - Parameter limit: Number of top features to return
    /// - Returns: Features sorted by usage (highest first)
    func getMostUsedFeatures(limit: Int = 5) -> [(PremiumFeature, Int)] {
        let sortedUsage = usageSummary.sorted { $0.value > $1.value }
        return Array(sortedUsage.prefix(limit)).map { ($0.key, $0.value) }
    }
    
    // MARK: - Debug Description
    
    /// Usage summary for debugging
    var description: String {
        let sortedUsage = usage.sorted { $0.value > $1.value }
        let usageStrings = sortedUsage.map { "\($0.key): \($0.value)" }
        let resetInfo = "Reset: \(DateFormatter.shortStyle.string(from: lastResetDate))"
        return "Usage: [\(usageStrings.joined(separator: ", "))] (\(resetInfo))"
    }
    
    /// Detailed usage report
    var detailedReport: String {
        var report = ["Premium Feature Usage Report"]
        report.append("Last Reset: \(DateFormatter.mediumStyle.string(from: lastResetDate))")
        report.append("Total Usage: \(totalUsage)")
        report.append("")
        
        for feature in PremiumFeature.allCases where feature.requiresPremium {
            let current = getUsage(for: feature)
            let limit = feature.freeTrialLimit
            let remaining = getRemainingUsage(for: feature)
            let percentage = Int(getUsagePercentage(for: feature) * 100)
            
            report.append("\(feature.displayName):")
            report.append("  Used: \(current)/\(limit) (\(percentage)%)")
            report.append("  Remaining: \(remaining)")
        }
        
        return report.joined(separator: "\n")
    }
}

// MARK: - Date Formatter Extensions

private extension DateFormatter {
    static let shortStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let mediumStyle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}