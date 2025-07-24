import Foundation
import Combine

// MARK: - Speech Recognition Engine Protocol

/// Common interface for all speech recognition engines (AssemblyAI, iOS Speech Framework)
/// Enables unified state management and seamless engine switching
protocol SpeechRecognitionEngine: ObservableObject {
    // MARK: - Published State Properties
    
    /// Whether the engine is currently streaming audio
    var isStreaming: Bool { get }
    
    /// Current transcribed text content
    var transcriptionText: String { get }
    
    /// Current connection/streaming state
    var connectionState: StreamingState { get }
    
    /// Current error message, if any
    var errorMessage: String? { get }
    
    // MARK: - Core Methods
    
    /// Start streaming audio and transcription
    func startStreaming() async
    
    /// Stop streaming audio and transcription
    func stopStreaming()
    
    /// Clear all transcribed text content
    func clearTranscriptionText()
    
    /// Configure the engine with required dependencies
    func configure(subscriptionManager: SubscriptionManager, authManager: AuthenticationManager)
}

// MARK: - Engine Configuration

/// Protocol for engine-specific configuration
protocol SpeechEngineConfigurable {
    /// Engine-specific settings and parameters
    associatedtype ConfigurationType
    
    /// Apply configuration to the engine
    func applyConfiguration(_ config: ConfigurationType)
}

// MARK: - Engine Capabilities

/// Protocol for querying engine capabilities
protocol SpeechEngineCapabilities {
    /// Whether the engine supports offline transcription
    var supportsOfflineTranscription: Bool { get }
    
    /// Whether the engine supports real-time streaming
    var supportsRealTimeStreaming: Bool { get }
    
    /// Whether the engine requires network connectivity
    var requiresNetworkConnection: Bool { get }
    
    /// Maximum supported audio duration (nil = unlimited)
    var maxAudioDuration: TimeInterval? { get }
    
    /// Supported languages for transcription
    var supportedLanguages: [String] { get }
}

// MARK: - Engine Performance Metrics

/// Protocol for engine performance tracking
protocol SpeechEngineMetrics {
    /// Average transcription latency in milliseconds
    var averageLatency: Double { get }
    
    /// Engine accuracy score (0.0-1.0)
    var accuracyScore: Double { get }
    
    /// Current network usage in bytes/second
    var networkUsage: Double { get }
    
    /// Battery impact level
    var batteryImpact: EngineBatteryImpact { get }
}

/// Battery impact levels for different engines
enum EngineBatteryImpact: CaseIterable {
    case low        // iOS Speech (on-device)
    case medium     // iOS Speech (server-based)
    case high       // AssemblyAI (cloud streaming)
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium" 
        case .high: return "High"
        }
    }
}

// MARK: - Engine Type Identification

/// Engine type identifier for UI and logic differentiation
enum SpeechEngineType: String, CaseIterable {
    case assemblyAI = "assemblyai"
    case iosSpeech = "ios_speech"
    
    var displayName: String {
        switch self {
        case .assemblyAI: return "AssemblyAI"
        case .iosSpeech: return "iOS Speech"
        }
    }
    
    var engineMode: SpeechRecognitionMode {
        switch self {
        case .assemblyAI: return .professional
        case .iosSpeech: return .fast
        }
    }
}

// MARK: - Engine Factory Protocol

/// Protocol for creating speech recognition engines
protocol SpeechEngineFactory {
    /// Create an engine instance of the specified type
    static func createEngine(type: SpeechEngineType) -> SpeechRecognitionEngine
    
    /// Get available engine types for the current device/environment
    static func availableEngineTypes() -> [SpeechEngineType]
}

// MARK: - Engine Switching Protocol

/// Protocol for handling engine transitions
protocol SpeechEngineTransition {
    /// Called before switching away from this engine
    func prepareForTransition() async
    
    /// Called after switching to this engine
    func didBecomeActive() async
    
    /// Export current state for preservation during switch
    func exportState() -> SpeechEngineState?
    
    /// Import state after switching to this engine
    func importState(_ state: SpeechEngineState?) async
}

// MARK: - Engine State Transfer

/// Transferable state between engines during switching
struct SpeechEngineState {
    let accumulatedText: String
    let currentSessionDuration: TimeInterval
    let lastActivityTimestamp: Date
    let customMetadata: [String: Any]
    
    init(accumulatedText: String = "", 
         currentSessionDuration: TimeInterval = 0,
         lastActivityTimestamp: Date = Date(),
         customMetadata: [String: Any] = [:]) {
        self.accumulatedText = accumulatedText
        self.currentSessionDuration = currentSessionDuration
        self.lastActivityTimestamp = lastActivityTimestamp
        self.customMetadata = customMetadata
    }
}

// MARK: - Engine Error Protocol

/// Protocol for engine-specific error handling
protocol SpeechEngineErrorHandling {
    /// Handle engine-specific errors
    func handleEngineError(_ error: Error) async
    
    /// Attempt to recover from the current error state
    func attemptErrorRecovery() async -> Bool
    
    /// Get user-friendly error message for the current error
    func getUserFriendlyErrorMessage() -> String?
}