import Foundation
import Network
import UIKit

// MARK: - RCP Network Client

/// Network client for sending RCP commands to Yamaha consoles or testing receivers
class RCPNetworkClient: ObservableObject {
    
    // MARK: - Properties
    
    /// Network settings configuration
    private let networkSettings = NetworkSettings.shared
    
    /// URLSession for HTTP communication
    private let urlSession: URLSession
    
    /// Network monitor for connection status
    private let networkMonitor = NWPathMonitor()
    
    /// Monitor queue
    private let monitorQueue = DispatchQueue(label: "network.monitor")
    
    /// Published connection status
    @Published var isNetworkAvailable = true
    
    // MARK: - Initialization
    
    init() {
        // Configure URLSession with timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: config)
        
        setupNetworkMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - Public Interface
    
    /// Send RCP command to configured targets
    /// - Parameter command: The processed voice command containing RCP data
    /// - Returns: Result with success message or error
    func sendRCPCommand(_ command: ProcessedVoiceCommand) async -> Result<String, RCPNetworkError> {
        guard networkSettings.isValidConfiguration else {
            return .failure(.invalidConfiguration("Invalid network configuration"))
        }
        
        guard isNetworkAvailable else {
            return .failure(.networkUnavailable("No network connection"))
        }
        
        // Update connection status  
        await MainActor.run {
            networkSettings.updateConnectionStatus(.connecting)
        }
        
        // Create command payload
        let payload = createCommandPayload(from: command)
        
        var results: [Result<String, RCPNetworkError>] = []
        
        // Send to console if configured
        if networkSettings.shouldSendToConsole {
            let consoleResult = await sendToTarget(
                payload: payload,
                ip: networkSettings.consoleIP,
                port: networkSettings.consolePort,
                targetName: "Yamaha Console"
            )
            results.append(consoleResult)
        }
        
        // Send to GUI testing receiver if configured
        if networkSettings.shouldSendToGUI {
            let guiResult = await sendToTarget(
                payload: payload,
                ip: networkSettings.testingIP,
                port: networkSettings.testingPort,
                targetName: "Mac GUI"
            )
            results.append(guiResult)
        }
        
        // Process results
        return processResults(results)
    }
    
    /// Test connection to a specific target
    /// - Parameters:
    ///   - ip: Target IP address
    ///   - port: Target port
    /// - Returns: Result with connection test outcome
    func testConnection(ip: String, port: Int) async -> Result<String, RCPNetworkError> {
        let testPayload = RCPCommandPayload(
            command: "get MIXER:Current/Scene/Name",
            description: "Connection test",
            confidence: 1.0,
            originalText: "test connection",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            deviceId: UIDevice.current.name,
            commandType: "test"
        )
        
        return await sendToTarget(
            payload: testPayload,
            ip: ip,
            port: port,
            targetName: "Test Target"
        )
    }
    
    /// Verify console connection for learning prompts
    /// Used by LearningPromptManager to determine if prompts should appear
    /// - Returns: True if connected to actual console (not GUI testing)
    func isConsoleConnectionVerified() async -> Bool {
        guard networkSettings.shouldSendToConsole else {
            if networkSettings.enableLogging {
                print("🔍 Console verification: Not configured to connect to console")
            }
            return false
        }
        
        // Test connection to console with console-specific command
        let verificationResult = await testConsoleCapabilities()
        
        switch verificationResult {
        case .success:
            if networkSettings.enableLogging {
                print("✅ Console verification: Successfully connected to Yamaha console")
            }
            return true
        case .failure(let error):
            if networkSettings.enableLogging {
                print("❌ Console verification failed: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Test console-specific capabilities to verify it's a real console
    /// - Returns: Result indicating if target is a real Yamaha console
    private func testConsoleCapabilities() async -> Result<String, RCPNetworkError> {
        // Use console-specific RCP command that only real consoles respond to
        let consoleTestPayload = RCPCommandPayload(
            command: "get MIXER:Current/InCh/Fader/Level 0 0",
            description: "Console capability test",
            confidence: 1.0,
            originalText: "console verification",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            deviceId: UIDevice.current.name,
            commandType: "console_verification"
        )
        
        return await sendToTarget(
            payload: consoleTestPayload,
            ip: networkSettings.consoleIP,
            port: networkSettings.consolePort,
            targetName: "Console Verification"
        )
    }
    
    /// Get current connection status for learning system
    /// - Returns: Current connection status
    func getCurrentConnectionStatus() -> ConnectionStatus {
        return networkSettings.connectionStatus
    }
    
    /// Check if connected to actual hardware (not testing GUI)
    /// - Returns: True if connected to real hardware
    func isConnectedToHardware() -> Bool {
        let status = networkSettings.connectionStatus
        
        switch status {
        case .connected(let target):
            // Consider it hardware if connected to "Yamaha Console" and not "Mac GUI"
            return target.contains("Console") || target.contains("Yamaha")
        default:
            return false
        }
    }
    
    /// Verify network connectivity and configuration
    /// - Returns: Comprehensive network status
    func verifyNetworkConfiguration() async -> NetworkVerificationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check basic network availability
        guard isNetworkAvailable else {
            issues.append("No network connection available")
            return NetworkVerificationResult(
                isValid: false,
                issues: issues,
                warnings: warnings,
                consoleReachable: false,
                guiReachable: false
            )
        }
        
        // Validate IP addresses and ports
        if networkSettings.shouldSendToConsole {
            if !isValidIPAddress(networkSettings.consoleIP) {
                issues.append("Invalid console IP address: \(networkSettings.consoleIP)")
            }
            if !isValidPort(networkSettings.consolePort) {
                issues.append("Invalid console port: \(networkSettings.consolePort)")
            }
        }
        
        if networkSettings.shouldSendToGUI {
            if !isValidIPAddress(networkSettings.testingIP) {
                issues.append("Invalid testing IP address: \(networkSettings.testingIP)")
            }
            if !isValidPort(networkSettings.testingPort) {
                issues.append("Invalid testing port: \(networkSettings.testingPort)")
            }
        }
        
        // Test connectivity if configuration is valid
        var consoleReachable = false
        var guiReachable = false
        
        if issues.isEmpty {
            // Test console connectivity
            if networkSettings.shouldSendToConsole {
                let consoleTest = await testConnection(
                    ip: networkSettings.consoleIP,
                    port: networkSettings.consolePort
                )
                consoleReachable = consoleTest.isSuccess
                if !consoleReachable {
                    warnings.append("Console not reachable at \(networkSettings.consoleIP):\(networkSettings.consolePort)")
                }
            }
            
            // Test GUI connectivity
            if networkSettings.shouldSendToGUI {
                let guiTest = await testConnection(
                    ip: networkSettings.testingIP,
                    port: networkSettings.testingPort
                )
                guiReachable = guiTest.isSuccess
                if !guiReachable {
                    warnings.append("GUI testing receiver not reachable at \(networkSettings.testingIP):\(networkSettings.testingPort)")
                }
            }
        }
        
        return NetworkVerificationResult(
            isValid: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            consoleReachable: consoleReachable,
            guiReachable: guiReachable
        )
    }
    
    // MARK: - Helper Methods
    
    /// Validate IP address format
    private func isValidIPAddress(_ ip: String) -> Bool {
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
    
    // MARK: - Private Implementation
    
    /// Send payload to specific target
    private func sendToTarget(
        payload: RCPCommandPayload,
        ip: String,
        port: Int,
        targetName: String
    ) async -> Result<String, RCPNetworkError> {
        
        do {
            // Create URL
            guard let url = URL(string: "http://\(ip):\(port)/rcp") else {
                return .failure(.invalidURL("Invalid URL: http://\(ip):\(port)/rcp"))
            }
            
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("VoiceControlApp/1.0", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = networkSettings.timeoutSeconds
            
            // Encode payload
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
            
            if networkSettings.enableLogging {
                print("🚀 Sending RCP command to \(targetName) (\(ip):\(port))")
                print("📡 Command: \(payload.command)")
                print("📝 Description: \(payload.description)")
            }
            
            // Send request
            let (data, response) = try await urlSession.data(for: request)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse("Invalid HTTP response"))
            }
            
            // Handle response status
            switch httpResponse.statusCode {
            case 200...299:
                // Success - parse response
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                
                await MainActor.run {
                    networkSettings.updateConnectionStatus(.connected(targetName))
                }
                
                if networkSettings.enableLogging {
                    print("✅ Success from \(targetName): \(responseString)")
                }
                
                return .success("Command sent successfully to \(targetName)")
                
            case 400...499:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
                return .failure(.clientError("Client error (\(httpResponse.statusCode)): \(errorMessage)"))
                
            case 500...599:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
                return .failure(.serverError("Server error (\(httpResponse.statusCode)): \(errorMessage)"))
                
            default:
                return .failure(.unexpectedStatusCode("Unexpected status code: \(httpResponse.statusCode)"))
            }
            
        } catch let error as URLError {
            let networkError = mapURLError(error)
            await MainActor.run {
                networkSettings.updateConnectionStatus(.error(networkError.localizedDescription))
            }
            
            if networkSettings.enableLogging {
                print("❌ Network error to \(targetName): \(networkError.localizedDescription)")
            }
            
            return .failure(networkError)
            
        } catch {
            let rcpError = RCPNetworkError.unknownError(error.localizedDescription)
            await MainActor.run {
                networkSettings.updateConnectionStatus(.error(error.localizedDescription))
            }
            
            if networkSettings.enableLogging {
                print("❌ Unknown error to \(targetName): \(error.localizedDescription)")
            }
            
            return .failure(rcpError)
        }
    }
    
    /// Create command payload from processed voice command
    private func createCommandPayload(from command: ProcessedVoiceCommand) -> RCPCommandPayload {
        return RCPCommandPayload(
            command: command.rcpCommand.command,
            description: command.rcpCommand.description,
            confidence: command.confidence,
            originalText: command.originalText,
            timestamp: ISO8601DateFormatter().string(from: command.timestamp),
            deviceId: UIDevice.current.name,
            commandType: "voice_command"
        )
    }
    
    /// Process multiple results and return combined outcome
    private func processResults(_ results: [Result<String, RCPNetworkError>]) -> Result<String, RCPNetworkError> {
        let successes = results.compactMap { result in
            if case .success(let message) = result {
                return message
            }
            return nil
        }
        
        let failures = results.compactMap { result in
            if case .failure(let error) = result {
                return error
            }
            return nil
        }
        
        if successes.isEmpty {
            // All failed
            let combinedError = failures.first ?? .unknownError("No results")
            return .failure(combinedError)
        } else if failures.isEmpty {
            // All successful
            let combinedMessage = successes.joined(separator: ", ")
            return .success(combinedMessage)
        } else {
            // Mixed results - return success with warning
            let message = "\(successes.count) succeeded, \(failures.count) failed"
            return .success(message)
        }
    }
    
    /// Map URLError to RCPNetworkError
    private func mapURLError(_ error: URLError) -> RCPNetworkError {
        switch error.code {
        case .notConnectedToInternet:
            return .networkUnavailable("Not connected to internet")
        case .timedOut:
            return .timeout("Connection timed out")
        case .cannotConnectToHost:
            return .connectionFailed("Cannot connect to host")
        case .networkConnectionLost:
            return .connectionFailed("Network connection lost")
        case .dnsLookupFailed:
            return .connectionFailed("DNS lookup failed")
        default:
            return .networkError("Network error: \(error.localizedDescription)")
        }
    }
    
    /// Setup network monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
}

// MARK: - RCP Command Payload

/// JSON payload structure for RCP commands
struct RCPCommandPayload: Codable {
    let command: String
    let description: String
    let confidence: Double
    let originalText: String
    let timestamp: String
    let deviceId: String
    let commandType: String
    
    /// Additional metadata for debugging
    var metadata: [String: String] {
        return [
            "source": "ios_voice_control",
            "version": "1.0",
            "platform": "iOS"
        ]
    }
}

// MARK: - RCP Network Errors

/// Comprehensive error types for RCP network communication
enum RCPNetworkError: LocalizedError, Equatable {
    case invalidConfiguration(String)
    case networkUnavailable(String)
    case invalidURL(String)
    case timeout(String)
    case connectionFailed(String)
    case clientError(String)
    case serverError(String)
    case invalidResponse(String)
    case unexpectedStatusCode(String)
    case networkError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration Error: \(message)"
        case .networkUnavailable(let message):
            return "Network Unavailable: \(message)"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .timeout(let message):
            return "Timeout: \(message)"
        case .connectionFailed(let message):
            return "Connection Failed: \(message)"
        case .clientError(let message):
            return "Client Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        case .unexpectedStatusCode(let message):
            return "Unexpected Status: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidConfiguration:
            return "Check network settings and IP addresses"
        case .networkUnavailable:
            return "Check WiFi connection and try again"
        case .invalidURL:
            return "Verify IP address format"
        case .timeout:
            return "Check network connection and target device"
        case .connectionFailed:
            return "Ensure target device is powered on and connected"
        case .clientError:
            return "Check command format and try again"
        case .serverError:
            return "Check target device status"
        case .invalidResponse:
            return "Target device may not support RCP protocol"
        default:
            return "Try again or check network settings"
        }
    }
}

// MARK: - Singleton Access

extension RCPNetworkClient {
    /// Shared network client instance
    static let shared = RCPNetworkClient()
}

// MARK: - Network Verification Result

/// Result of comprehensive network verification
struct NetworkVerificationResult {
    let isValid: Bool
    let issues: [String]
    let warnings: [String]
    let consoleReachable: Bool
    let guiReachable: Bool
    
    /// Human-readable summary of the verification
    var summary: String {
        if isValid && issues.isEmpty && warnings.isEmpty {
            return "✅ Network configuration is valid and all targets are reachable"
        } else if isValid && warnings.isEmpty {
            return "✅ Network configuration is valid"
        } else if isValid {
            return "⚠️ Network configuration is valid but has warnings"
        } else {
            return "❌ Network configuration has issues"
        }
    }
    
    /// Detailed status report
    var detailedReport: String {
        var report = [summary]
        
        if !issues.isEmpty {
            report.append("\nIssues:")
            for issue in issues {
                report.append("  • \(issue)")
            }
        }
        
        if !warnings.isEmpty {
            report.append("\nWarnings:")
            for warning in warnings {
                report.append("  • \(warning)")
            }
        }
        
        report.append("\nConnectivity:")
        report.append("  • Console: \(consoleReachable ? "✅ Reachable" : "❌ Not reachable")")
        report.append("  • GUI Testing: \(guiReachable ? "✅ Reachable" : "❌ Not reachable")")
        
        return report.joined(separator: "\n")
    }
}

// MARK: - Result Extension

extension Result {
    /// Check if the result is a success
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}