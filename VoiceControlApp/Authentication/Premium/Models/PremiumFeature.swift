import Foundation

// MARK: - Premium Feature Definitions

/// Available premium features in the voice control app
enum PremiumFeature: String, CaseIterable, Codable {
    case cloudSync = "cloud_sync"
    case advancedAnalytics = "advanced_analytics"
    case customCommands = "custom_commands"
    case prioritySupport = "priority_support"
    case basicVoiceCommands = "basic_voice_commands"
    case localDictionary = "local_dictionary"
    
    var displayName: String {
        switch self {
        case .cloudSync:
            return "Cloud Sync"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .customCommands:
            return "Custom Commands"
        case .prioritySupport:
            return "Priority Support"
        case .basicVoiceCommands:
            return "Basic Voice Commands"
        case .localDictionary:
            return "Local Dictionary"
        }
    }
    
    var description: String {
        switch self {
        case .cloudSync:
            return "Sync your personal dictionary and settings across devices"
        case .advancedAnalytics:
            return "Detailed learning analytics and performance insights"
        case .customCommands:
            return "Create unlimited custom voice commands"
        case .prioritySupport:
            return "Priority customer support and feature requests"
        case .basicVoiceCommands:
            return "Basic voice command functionality"
        case .localDictionary:
            return "Local personal dictionary storage"
        }
    }
    
    /// Free trial limit for this feature
    var freeTrialLimit: Int {
        switch self {
        case .cloudSync:
            return 5 // 5 sync operations
        case .advancedAnalytics:
            return 10 // 10 analytics views
        case .customCommands:
            return 3 // 3 custom commands
        case .prioritySupport:
            return 1 // 1 priority support ticket
        case .basicVoiceCommands:
            return Int.max // Unlimited for free users
        case .localDictionary:
            return Int.max // Unlimited for free users
        }
    }
    
    /// Whether this feature requires premium subscription
    var requiresPremium: Bool {
        switch self {
        case .cloudSync, .advancedAnalytics, .customCommands, .prioritySupport:
            return true
        case .basicVoiceCommands, .localDictionary:
            return false
        }
    }
    
    /// Icon name for UI display
    var iconName: String {
        switch self {
        case .cloudSync:
            return "icloud.and.arrow.up"
        case .advancedAnalytics:
            return "chart.bar"
        case .customCommands:
            return "mic.badge.plus"
        case .prioritySupport:
            return "person.badge.shield.checkmark"
        case .basicVoiceCommands:
            return "mic"
        case .localDictionary:
            return "book"
        }
    }
}