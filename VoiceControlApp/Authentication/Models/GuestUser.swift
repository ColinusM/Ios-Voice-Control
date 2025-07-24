import Foundation
import UIKit

// MARK: - Guest User Model

/// Represents an anonymous guest user with API usage tracking
/// Complies with Apple Guideline 2.1 by allowing app access without mandatory authentication
struct GuestUser: Codable, Identifiable {
    
    // MARK: - Properties
    
    let id: String
    let sessionId: String
    let startDate: Date
    let deviceIdentifier: String
    var totalAPIMinutesUsed: Int  // Total minutes of AssemblyAI API usage consumed
    
    // MARK: - Computed Properties
    
    /// Minutes of free API usage remaining out of 60 minutes (1 hour)
    var remainingFreeMinutes: Int {
        max(0, 60 - totalAPIMinutesUsed)  // 1 hour (60 minutes) free
    }
    
    /// Whether the guest user can make API calls (has remaining free usage)
    var canMakeAPICall: Bool {
        remainingFreeMinutes > 0
    }
    
    /// Percentage of free hour used (0.0 to 1.0)
    var usagePercentage: Double {
        Double(totalAPIMinutesUsed) / 60.0  // Percentage of free hour used
    }
    
    /// Usage warning level based on remaining minutes
    var usageWarningLevel: UsageWarningLevel {
        switch remainingFreeMinutes {
        case 0...6:  // 10% remaining (6 minutes or less)
            return .critical
        case 7...15: // 25% remaining (15 minutes or less)
            return .warning
        default:
            return .none
        }
    }
    
    /// Display text for remaining usage
    var remainingUsageText: String {
        if remainingFreeMinutes == 0 {
            return "No free time remaining"
        } else if remainingFreeMinutes == 1 {
            return "1 minute remaining"
        } else {
            return "\(remainingFreeMinutes) minutes remaining"
        }
    }
    
    /// Minutes used as a formatted string
    var usedTimeText: String {
        if totalAPIMinutesUsed == 0 {
            return "No usage yet"
        } else if totalAPIMinutesUsed == 1 {
            return "1 minute used"
        } else {
            return "\(totalAPIMinutesUsed) minutes used"
        }
    }
    
    // MARK: - Initialization
    
    init(deviceIdentifier: String = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString) {
        self.id = UUID().uuidString
        self.sessionId = UUID().uuidString
        self.startDate = Date()
        self.deviceIdentifier = deviceIdentifier
        self.totalAPIMinutesUsed = 0
    }
    
    // MARK: - Usage Tracking
    
    /// Increments API usage by the specified number of minutes
    /// - Parameter minutes: Number of minutes to add to usage
    /// - Returns: Updated GuestUser with incremented usage
    func incrementUsage(by minutes: Int) -> GuestUser {
        var updatedUser = self
        updatedUser.totalAPIMinutesUsed = min(60, totalAPIMinutesUsed + minutes) // Cap at 60 minutes
        return updatedUser
    }
    
    /// Resets usage back to zero (for testing or promotional purposes)
    /// - Returns: Updated GuestUser with reset usage
    func resetUsage() -> GuestUser {
        var updatedUser = self
        updatedUser.totalAPIMinutesUsed = 0
        return updatedUser
    }
    
    // MARK: - Persistence Keys
    
    struct UserDefaultsKeys {
        static let guestUser = "guest_user"
        static let totalAPIMinutesUsed = "total_api_minutes_used"
        static let guestSessionStart = "guest_session_start"
        static let lastWarningShown = "last_warning_shown"
    }
}

// MARK: - Usage Warning Level

enum UsageWarningLevel: String, CaseIterable {
    case none = "none"
    case warning = "warning"      // 75% usage (15 minutes remaining)
    case critical = "critical"    // 90% usage (6 minutes remaining)
    
    var shouldShowWarning: Bool {
        self != .none
    }
    
    var warningTitle: String {
        switch self {
        case .none:
            return ""
        case .warning:
            return "Usage Warning"
        case .critical:
            return "Usage Almost Exhausted"
        }
    }
    
    var warningMessage: String {
        switch self {
        case .none:
            return ""
        case .warning:
            return "You've used 75% of your free usage. Consider upgrading to Voice Control Pro for unlimited access."
        case .critical:
            return "You've used 90% of your free usage. Upgrade now to continue using voice controls without limits."
        }
    }
    
    var actionButtonText: String {
        switch self {
        case .none:
            return ""
        case .warning:
            return "Learn More"
        case .critical:
            return "Upgrade Now"
        }
    }
}

// MARK: - Guest User Extensions

extension GuestUser {
    
    /// Creates a guest user from UserDefaults if available
    static func fromUserDefaults() -> GuestUser? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKeys.guestUser) else {
            return nil
        }
        
        do {
            let guestUser = try JSONDecoder().decode(GuestUser.self, from: data)
            return guestUser
        } catch {
            #if DEBUG
            print("❌ Failed to decode GuestUser from UserDefaults: \(error)")
            #endif
            return nil
        }
    }
    
    /// Saves the guest user to UserDefaults
    /// - Returns: Whether the save operation was successful
    @discardableResult
    func saveToUserDefaults() -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.guestUser)
            UserDefaults.standard.set(totalAPIMinutesUsed, forKey: UserDefaultsKeys.totalAPIMinutesUsed)
            UserDefaults.standard.set(startDate, forKey: UserDefaultsKeys.guestSessionStart)
            return true
        } catch {
            #if DEBUG
            print("❌ Failed to save GuestUser to UserDefaults: \(error)")
            #endif
            return false
        }
    }
    
    /// Removes guest user data from UserDefaults
    static func clearFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.guestUser)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.totalAPIMinutesUsed)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.guestSessionStart)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWarningShown)
    }
}

// MARK: - Debug Description

extension GuestUser: CustomStringConvertible {
    var description: String {
        return """
        GuestUser(
            id: \(id)
            sessionId: \(sessionId)
            deviceId: \(deviceIdentifier)
            startDate: \(startDate)
            totalAPIMinutesUsed: \(totalAPIMinutesUsed)/60
            remainingFreeMinutes: \(remainingFreeMinutes)
            usagePercentage: \(String(format: "%.1f", usagePercentage * 100))%
            warningLevel: \(usageWarningLevel.rawValue)
            canMakeAPICall: \(canMakeAPICall)
        )
        """
    }
}