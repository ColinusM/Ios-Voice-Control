import Foundation
import Network

// MARK: - RCP Network Client

/// Network client for sending RCP commands to Yamaha consoles or testing receivers
@MainActor
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
        await networkSettings.updateConnectionStatus(.connecting)
        
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
                
                await networkSettings.updateConnectionStatus(.connected(targetName))
                
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
            await networkSettings.updateConnectionStatus(.error(networkError.localizedDescription))
            
            if networkSettings.enableLogging {
                print("❌ Network error to \(targetName): \(networkError.localizedDescription)")
            }
            
            return .failure(networkError)
            
        } catch {
            let rcpError = RCPNetworkError.unknownError(error.localizedDescription)
            await networkSettings.updateConnectionStatus(.error(error.localizedDescription))
            
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