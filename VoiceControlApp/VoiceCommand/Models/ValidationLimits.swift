import Foundation

/// Validation limits and constraints for voice command processing
/// Provides centralized validation for audio engineering parameters
struct ValidationLimits {
    
    // MARK: - Input Validation
    
    /// Maximum length for voice command input text
    static let maxInputLength: Int = 500
    
    // MARK: - Channel Validation
    
    /// Minimum valid channel number (1-based indexing)
    static let minChannel: Int = 1
    
    /// Maximum valid channel number for typical mixing consoles
    static let maxChannel: Int = 64
    
    /// Validates if a channel number is within acceptable range
    /// - Parameter channel: Channel number to validate (1-based)
    /// - Returns: True if channel is valid, false otherwise
    static func isValidChannel(_ channel: Int) -> Bool {
        return channel >= minChannel && channel <= maxChannel
    }
    
    // MARK: - Audio Level Validation
    
    /// Minimum dB level for fader control
    static let minDB: Double = -60.0
    
    /// Maximum dB level for fader control
    static let maxDB: Double = 10.0
    
    /// Clamps dB level to valid range
    /// - Parameter level: dB level to clamp
    /// - Returns: Clamped dB level within valid range
    static func clampDB(_ level: Double) -> Double {
        return max(minDB, min(maxDB, level))
    }
    
    /// Validates if a dB level is within acceptable range
    /// - Parameter level: dB level to validate
    /// - Returns: True if level is valid, false otherwise
    static func isValidDB(_ level: Double) -> Bool {
        return level >= minDB && level <= maxDB
    }
    
    // MARK: - Scene Validation
    
    /// Minimum valid scene number
    static let minScene: Int = 1
    
    /// Maximum valid scene number for typical mixing consoles
    static let maxScene: Int = 100
    
    /// Validates if a scene number is within acceptable range
    /// - Parameter scene: Scene number to validate
    /// - Returns: True if scene is valid, false otherwise
    static func isValidScene(_ scene: Int) -> Bool {
        return scene >= minScene && scene <= maxScene
    }
    
    // MARK: - Pan Validation
    
    /// Minimum pan value (-100 = full left)
    static let minPan: Double = -100.0
    
    /// Maximum pan value (100 = full right)
    static let maxPan: Double = 100.0
    
    /// Center pan position
    static let centerPan: Double = 0.0
    
    /// Clamps pan value to valid range
    /// - Parameter pan: Pan value to clamp
    /// - Returns: Clamped pan value within valid range
    static func clampPan(_ pan: Double) -> Double {
        return max(minPan, min(maxPan, pan))
    }
    
    /// Validates if a pan value is within acceptable range
    /// - Parameter pan: Pan value to validate
    /// - Returns: True if pan is valid, false otherwise
    static func isValidPan(_ pan: Double) -> Bool {
        return pan >= minPan && pan <= maxPan
    }
    
    // MARK: - Frequency Validation (for EQ)
    
    /// Minimum frequency for EQ control (Hz)
    static let minFrequency: Double = 20.0
    
    /// Maximum frequency for EQ control (Hz)
    static let maxFrequency: Double = 20000.0
    
    /// Validates if a frequency is within acceptable range
    /// - Parameter frequency: Frequency in Hz to validate
    /// - Returns: True if frequency is valid, false otherwise
    static func isValidFrequency(_ frequency: Double) -> Bool {
        return frequency >= minFrequency && frequency <= maxFrequency
    }
    
    // MARK: - Send Level Validation
    
    /// Minimum send level (typically 0 for off)
    static let minSendLevel: Double = 0.0
    
    /// Maximum send level (typically 100 for unity)
    static let maxSendLevel: Double = 100.0
    
    /// Clamps send level to valid range
    /// - Parameter level: Send level to clamp
    /// - Returns: Clamped send level within valid range
    static func clampSendLevel(_ level: Double) -> Double {
        return max(minSendLevel, min(maxSendLevel, level))
    }
    
    /// Validates if a send level is within acceptable range
    /// - Parameter level: Send level to validate
    /// - Returns: True if level is valid, false otherwise
    static func isValidSendLevel(_ level: Double) -> Bool {
        return level >= minSendLevel && level <= maxSendLevel
    }
    
    // MARK: - Time-based Validation (for delays, reverbs)
    
    /// Minimum delay time in milliseconds
    static let minDelayMs: Double = 0.0
    
    /// Maximum delay time in milliseconds
    static let maxDelayMs: Double = 2000.0
    
    /// Validates if a delay time is within acceptable range
    /// - Parameter delayMs: Delay time in milliseconds to validate
    /// - Returns: True if delay time is valid, false otherwise
    static func isValidDelayMs(_ delayMs: Double) -> Bool {
        return delayMs >= minDelayMs && delayMs <= maxDelayMs
    }
    
    // MARK: - Percentage Validation (for effects parameters)
    
    /// Minimum percentage value
    static let minPercentage: Double = 0.0
    
    /// Maximum percentage value
    static let maxPercentage: Double = 100.0
    
    /// Clamps percentage to valid range
    /// - Parameter percentage: Percentage to clamp
    /// - Returns: Clamped percentage within valid range
    static func clampPercentage(_ percentage: Double) -> Double {
        return max(minPercentage, min(maxPercentage, percentage))
    }
    
    /// Validates if a percentage is within acceptable range
    /// - Parameter percentage: Percentage to validate
    /// - Returns: True if percentage is valid, false otherwise
    static func isValidPercentage(_ percentage: Double) -> Bool {
        return percentage >= minPercentage && percentage <= maxPercentage
    }
    
    // MARK: - Network Validation
    
    /// Minimum valid port number
    static let minPort: Int = 1
    
    /// Maximum valid port number
    static let maxPort: Int = 65535
    
    /// Validates if a port number is within acceptable range
    /// - Parameter port: Port number to validate
    /// - Returns: True if port is valid, false otherwise
    static func isValidPort(_ port: Int) -> Bool {
        return port >= minPort && port <= maxPort
    }
    
    // MARK: - Confidence Validation
    
    /// Minimum confidence level for processing
    static let minConfidence: Double = 0.0
    
    /// Maximum confidence level
    static let maxConfidence: Double = 1.0
    
    /// Default minimum confidence threshold for command processing
    static let defaultConfidenceThreshold: Double = 0.5
    
    /// Validates if a confidence value is within acceptable range
    /// - Parameter confidence: Confidence value to validate
    /// - Returns: True if confidence is valid, false otherwise
    static func isValidConfidence(_ confidence: Double) -> Bool {
        return confidence >= minConfidence && confidence <= maxConfidence
    }
}

// MARK: - Preview Helper

#if DEBUG
extension ValidationLimits {
    /// Test values for development and previews
    struct TestValues {
        static let validChannel = 5
        static let invalidChannel = 100
        static let validDB = -6.0
        static let invalidDB = 50.0
        static let validScene = 10
        static let invalidScene = 200
        static let validPan = 25.0
        static let invalidPan = 150.0
        static let validFrequency = 1000.0
        static let invalidFrequency = 50000.0
    }
}
#endif