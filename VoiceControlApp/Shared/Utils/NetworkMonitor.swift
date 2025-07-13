import Foundation
import Network
import SwiftUI

// MARK: - Network Monitor

@Observable
class NetworkMonitor {
    
    // MARK: - Published Properties
    
    var isConnected = false
    var connectionType: ConnectionType = .unknown
    var isExpensive = false
    var isConstrained = false
    
    // MARK: - Private Properties
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Status Updates
    
    private func updateNetworkStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = getConnectionType(from: path)
        
        // Log network changes in debug mode
        #if DEBUG
        logNetworkChange()
        #endif
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .unknown
        }
    }
    
    // MARK: - Public Methods
    
    /// Returns true if the device has an active internet connection
    var hasInternetConnection: Bool {
        return isConnected
    }
    
    /// Returns true if the connection is suitable for large data transfers
    var isSuitableForLargeTransfers: Bool {
        return isConnected && !isExpensive && !isConstrained
    }
    
    /// Returns true if the connection is cellular and potentially expensive
    var isCellularConnection: Bool {
        return connectionType == .cellular
    }
    
    /// Returns true if connected via WiFi
    var isWiFiConnection: Bool {
        return connectionType == .wifi
    }
    
    /// Returns a description of the current network status
    var statusDescription: String {
        if !isConnected {
            return "No Internet Connection"
        }
        
        var description = connectionType.description
        
        if isExpensive {
            description += " (Expensive)"
        }
        
        if isConstrained {
            description += " (Constrained)"
        }
        
        return description
    }
    
    /// Performs a network connectivity test
    func performConnectivityTest() async -> ConnectivityTestResult {
        guard isConnected else {
            return .failed(.noConnection)
        }
        
        do {
            let url = URL(string: "https://www.google.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    return .success
                } else {
                    return .failed(.serverError(httpResponse.statusCode))
                }
            } else {
                return .failed(.invalidResponse)
            }
        } catch {
            return .failed(.requestFailed(error))
        }
    }
    
    // MARK: - Debug Logging
    
    #if DEBUG
    private func logNetworkChange() {
        print("🌐 Network Status Changed:")
        print("   Connected: \(isConnected)")
        print("   Type: \(connectionType.description)")
        print("   Expensive: \(isExpensive)")
        print("   Constrained: \(isConstrained)")
    }
    #endif
}

// MARK: - Connection Type

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case loopback
    case unknown
    
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .unknown:
            return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .loopback:
            return "arrow.triangle.2.circlepath"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Connectivity Test Result

enum ConnectivityTestResult {
    case success
    case failed(ConnectivityTestError)
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

enum ConnectivityTestError {
    case noConnection
    case serverError(Int)
    case invalidResponse
    case requestFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid server response"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network-Aware Operations

extension NetworkMonitor {
    
    /// Waits for network connection with timeout
    func waitForConnection(timeout: TimeInterval = 10.0) async -> Bool {
        if isConnected {
            return true
        }
        
        return await withCheckedContinuation { continuation in
            var hasResumed = false
            let timeoutWorkItem = DispatchWorkItem {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: false)
                }
            }
            
            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
            
            // Monitor for connection
            let checkConnection = {
                if self.isConnected && !hasResumed {
                    hasResumed = true
                    timeoutWorkItem.cancel()
                    continuation.resume(returning: true)
                }
            }
            
            // Use a timer to periodically check connection
            let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                checkConnection()
                if hasResumed {
                    timer.invalidate()
                }
            }
            
            // Check immediately
            checkConnection()
        }
    }
    
    /// Executes a network operation with retry logic
    func executeWithRetry<T>(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            // Wait for connection if needed
            if !isConnected {
                let connected = await waitForConnection(timeout: 5.0)
                if !connected {
                    throw NetworkError.noConnection
                }
            }
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on the last attempt
                if attempt == maxRetries {
                    break
                }
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError:
            return "Server error"
        case .unknown:
            return "Unknown network error"
        }
    }
}

// MARK: - SwiftUI Integration

struct NetworkStatusView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: networkMonitor.connectionType.icon)
                .foregroundColor(networkMonitor.isConnected ? .green : .red)
            
            Text(networkMonitor.statusDescription)
                .font(.caption)
                .foregroundColor(networkMonitor.isConnected ? .primary : .red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - View Modifier for Network Awareness

struct NetworkAwareModifier: ViewModifier {
    @Environment(NetworkMonitor.self) private var networkMonitor
    let showOfflineMessage: Bool
    let offlineMessage: String
    
    init(showOfflineMessage: Bool = true, offlineMessage: String = "No Internet Connection") {
        self.showOfflineMessage = showOfflineMessage
        self.offlineMessage = offlineMessage
    }
    
    func body(content: Content) -> some View {
        VStack {
            if !networkMonitor.isConnected && showOfflineMessage {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    
                    Text(offlineMessage)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.red)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            content
                .opacity(networkMonitor.isConnected ? 1.0 : 0.6)
        }
    }
}

// MARK: - View Extensions

extension View {
    
    /// Makes the view network-aware with offline messaging
    func networkAware(
        showOfflineMessage: Bool = true,
        offlineMessage: String = "No Internet Connection"
    ) -> some View {
        modifier(NetworkAwareModifier(
            showOfflineMessage: showOfflineMessage,
            offlineMessage: offlineMessage
        ))
    }
}