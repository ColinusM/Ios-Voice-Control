import Foundation

// MARK: - Network Target Types

/// Defines where RCP commands should be sent
enum NetworkTargetType: String, CaseIterable {
    case console = "console"
    case testing = "testing"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .console:
            return "Yamaha Console"
        case .testing:
            return "Mac GUI (Testing)"
        case .both:
            return "Console + GUI"
        }
    }
    
    var description: String {
        switch self {
        case .console:
            return "Send commands directly to Yamaha mixing console"
        case .testing:
            return "Send commands to Mac GUI receiver for development"
        case .both:
            return "Send to console and show in Mac GUI for monitoring"
        }
    }
}

// MARK: - Network Settings Model

/// Configuration settings for RCP command network transmission
class NetworkSettings: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current target type for RCP commands
    @Published var targetType: NetworkTargetType = .testing
    
    /// Yamaha console IP address
    @Published var consoleIP: String = "192.168.1.100"
    
    /// Yamaha console port (standard RCP port)
    @Published var consolePort: Int = 49280
    
    /// Mac GUI receiver IP address  
    @Published var testingIP: String = "192.168.1.50"
    
    /// Mac GUI receiver port
    @Published var testingPort: Int = 8080
    
    /// Connection timeout in seconds
    @Published var timeoutSeconds: Double = 5.0
    
    /// Enable detailed network logging
    @Published var enableLogging: Bool = true
    
    /// Last successful connection timestamp
    @Published var lastConnectionTime: Date?
    
    /// Current connection status
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Singleton
    
    static let shared = NetworkSettings()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let targetType = "networkTargetType"
        static let consoleIP = "consoleIP"
        static let consolePort = "consolePort"
        static let testingIP = "testingIP"
        static let testingPort = "testingPort"
        static let timeoutSeconds = "networkTimeoutSeconds"
        static let enableLogging = "networkEnableLogging"
        static let lastConnectionTime = "lastConnectionTime"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Computed Properties
    
    /// Get the primary target IP based on current settings
    var primaryTargetIP: String {
        switch targetType {
        case .console, .both:
            return consoleIP
        case .testing:
            return testingIP
        }
    }
    
    /// Get the primary target port based on current settings
    var primaryTargetPort: Int {
        switch targetType {
        case .console, .both:
            return consolePort
        case .testing:
            return testingPort
        }
    }
    
    /// Check if console communication is enabled
    var shouldSendToConsole: Bool {
        return targetType == .console || targetType == .both
    }
    
    /// Check if GUI testing communication is enabled
    var shouldSendToGUI: Bool {
        return targetType == .testing || targetType == .both
    }
    
    /// Validate current network configuration
    var isValidConfiguration: Bool {
        let consoleValid = isValidIP(consoleIP) && isValidPort(consolePort)
        let testingValid = isValidIP(testingIP) && isValidPort(testingPort)
        
        switch targetType {
        case .console:
            return consoleValid
        case .testing:
            return testingValid
        case .both:
            return consoleValid && testingValid
        }
    }
    
    // MARK: - Settings Persistence
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let targetTypeString = defaults.object(forKey: Keys.targetType) as? String,
           let targetType = NetworkTargetType(rawValue: targetTypeString) {
            self.targetType = targetType
        }
        
        if let consoleIP = defaults.object(forKey: Keys.consoleIP) as? String {
            self.consoleIP = consoleIP
        }
        
        consolePort = defaults.object(forKey: Keys.consolePort) as? Int ?? 49280
        
        if let testingIP = defaults.object(forKey: Keys.testingIP) as? String {
            self.testingIP = testingIP
        }
        
        testingPort = defaults.object(forKey: Keys.testingPort) as? Int ?? 8080
        timeoutSeconds = defaults.object(forKey: Keys.timeoutSeconds) as? Double ?? 5.0
        enableLogging = defaults.object(forKey: Keys.enableLogging) as? Bool ?? true
        
        if let lastConnectionData = defaults.object(forKey: Keys.lastConnectionTime) as? Data {
            lastConnectionTime = try? JSONDecoder().decode(Date.self, from: lastConnectionData)
        }
    }
    
    /// Save settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(targetType.rawValue, forKey: Keys.targetType)
        defaults.set(consoleIP, forKey: Keys.consoleIP)
        defaults.set(consolePort, forKey: Keys.consolePort)
        defaults.set(testingIP, forKey: Keys.testingIP)
        defaults.set(testingPort, forKey: Keys.testingPort)
        defaults.set(timeoutSeconds, forKey: Keys.timeoutSeconds)
        defaults.set(enableLogging, forKey: Keys.enableLogging)
        
        if let lastConnectionTime = lastConnectionTime,
           let data = try? JSONEncoder().encode(lastConnectionTime) {
            defaults.set(data, forKey: Keys.lastConnectionTime)
        }
        
        defaults.synchronize()
        
        if enableLogging {
            print("📝 Network settings saved - Target: \(targetType.displayName)")
        }
    }
    
    // MARK: - Connection Status Management
    
    /// Update connection status and timestamp
    func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
        
        if case .connected = status {
            lastConnectionTime = Date()
            saveSettings()
        }
        
        if enableLogging {
            print("🌐 Connection status: \(status)")
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validate IP address format
    private func isValidIP(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        
        return parts.allSatisfy { part in
            guard let num = Int(part), num >= 0, num <= 255 else { return false }
            return true
        }
    }
    
    /// Validate port number
    private func isValidPort(_ port: Int) -> Bool {
        return port > 0 && port <= 65535
    }
    
    // MARK: - Factory Defaults
    
    /// Reset to factory default settings
    func resetToDefaults() {
        targetType = .testing
        consoleIP = "192.168.1.100"
        consolePort = 49280
        testingIP = "192.168.1.50"
        testingPort = 8080
        timeoutSeconds = 5.0
        enableLogging = true
        lastConnectionTime = nil
        connectionStatus = .disconnected
        
        saveSettings()
        
        print("🔄 Network settings reset to defaults")
    }
}

// MARK: - Connection Status

/// Represents the current network connection status
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected(String) // Connected with target info
    case error(String)     // Error with description
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected(let target):
            return "Connected to \(target)"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

// MARK: - Preview Helper

#if DEBUG
extension NetworkSettings {
    /// Create settings instance for SwiftUI previews
    static var preview: NetworkSettings {
        let settings = NetworkSettings()
        settings.targetType = .testing
        settings.consoleIP = "192.168.1.100"
        settings.testingIP = "192.168.1.50"
        settings.connectionStatus = .connected("Mac GUI")
        return settings
    }
}
#endif