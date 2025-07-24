import Foundation
import Combine
import SwiftUI

// MARK: - Unified Speech Recognition Manager

/// Coordinates between AssemblyAI and iOS Speech Framework engines
/// Provides seamless switching and unified state management for the orbital toggle system
class SpeechRecognitionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently active speech recognition engine mode
    @Published var activeEngine: SpeechRecognitionMode = .professional
    
    /// Whether any engine is currently recording
    @Published var isRecording: Bool = false
    
    /// Combined transcription text from active engine
    @Published var transcriptionText: String = ""
    
    /// Current connection state of active engine
    @Published var connectionState: StreamingState = .disconnected
    
    /// Current error message from active engine
    @Published var errorMessage: String?
    
    /// Whether an engine switch is in progress
    @Published var isSwitchingEngines: Bool = false
    
    /// Performance metrics for current engine
    @Published var currentEngineMetrics: EnginePerformanceMetrics = EnginePerformanceMetrics()
    
    // MARK: - Engine Instances
    
    private let assemblyAIEngine: AssemblyAIStreamer
    private let iosSpeechEngine: IOSSpeechRecognizer
    
    // MARK: - State Management
    
    private var cancellables = Set<AnyCancellable>()
    private var isConfigured = false
    private var preservedState: SpeechEngineState?
    
    // MARK: - Dependencies
    
    private weak var subscriptionManager: SubscriptionManager?
    private weak var authManager: AuthenticationManager?
    
    // MARK: - Performance Tracking
    
    private var switchStartTime: Date?
    private var sessionStats = SessionStatistics()
    
    // MARK: - Initialization
    
    init() {
        self.assemblyAIEngine = AssemblyAIStreamer()
        self.iosSpeechEngine = IOSSpeechRecognizer()
        
        setupInitialEngine()
        print("🎯 SpeechRecognitionManager initialized with \(activeEngine.displayName) engine")
    }
    
    // MARK: - Configuration
    
    /// Configure the manager with required dependencies
    func configure(subscriptionManager: SubscriptionManager, authManager: AuthenticationManager) {
        self.subscriptionManager = subscriptionManager
        self.authManager = authManager
        
        // Configure both engines
        assemblyAIEngine.configure(subscriptionManager: subscriptionManager, authManager: authManager)
        iosSpeechEngine.configure(subscriptionManager: subscriptionManager, authManager: authManager)
        
        self.isConfigured = true
        
        // Setup initial engine bindings
        bindToActiveEngine()
        
        print("✅ SpeechRecognitionManager configured with dependencies")
    }
    
    // MARK: - Engine Management
    
    /// Get the currently active speech recognition engine
    private var currentEngine: SpeechRecognitionEngine {
        switch activeEngine {
        case .professional:
            return assemblyAIEngine
        case .fast:
            return iosSpeechEngine
        }
    }
    
    /// Switch to a different speech recognition engine
    func switchEngine(to newEngine: SpeechRecognitionMode) async {
        guard newEngine != activeEngine else {
            print("⚠️ Already using \(newEngine.displayName) engine")
            return
        }
        
        guard isConfigured else {
            print("❌ Cannot switch engines - manager not configured")
            return
        }
        
        print("🔄 Switching from \(activeEngine.displayName) to \(newEngine.displayName) engine...")
        
        switchStartTime = Date()
        
        await MainActor.run {
            isSwitchingEngines = true
            errorMessage = nil
        }
        
        let wasRecording = isRecording
        let preservedText = transcriptionText
        
        // Stop current engine if recording
        if wasRecording {
            print("⏸️ Stopping current engine for switch...")
            currentEngine.stopStreaming()
            
            // Preserve current state
            preservedState = SpeechEngineState(
                accumulatedText: preservedText,
                currentSessionDuration: sessionStats.currentSessionDuration,
                lastActivityTimestamp: Date()
            )
        }
        
        // Switch to new engine
        await MainActor.run {
            activeEngine = newEngine
            
            // Update performance metrics
            updateEngineMetrics()
        }
        
        // Bind to new engine
        bindToActiveEngine()
        
        // Restore state if needed
        if wasRecording {
            print("▶️ Restarting recording with new engine...")
            
            // Restore preserved text immediately
            if !preservedText.isEmpty {
                await MainActor.run {
                    transcriptionText = preservedText
                }
            }
            
            // Start new engine
            await currentEngine.startStreaming()
            
            // Track successful switch
            trackEngineSwitch(successful: true)
        }
        
        await MainActor.run {
            isSwitchingEngines = false
        }
        
        let switchDuration = switchStartTime.map { Date().timeIntervalSince($0) * 1000 } ?? 0
        print("✅ Engine switch completed in \(String(format: "%.1f", switchDuration))ms")
    }
    
    // MARK: - Recording Control
    
    /// Start recording with the current engine
    func startRecording() async {
        guard isConfigured else {
            await MainActor.run {
                errorMessage = "Speech recognition not configured"
            }
            return
        }
        
        guard !isSwitchingEngines else {
            print("⚠️ Cannot start recording during engine switch")
            return
        }
        
        print("🎤 Starting recording with \(activeEngine.displayName) engine...")
        
        sessionStats.startSession()
        await currentEngine.startStreaming()
    }
    
    /// Stop recording with the current engine
    func stopRecording() {
        guard !isSwitchingEngines else {
            print("⚠️ Cannot stop recording during engine switch")
            return
        }
        
        print("🛑 Stopping recording with \(activeEngine.displayName) engine...")
        
        currentEngine.stopStreaming()
        sessionStats.endSession()
    }
    
    /// Clear all transcription text
    func clearTranscriptionText() {
        currentEngine.clearTranscriptionText()
        preservedState = nil
        sessionStats.reset()
        
        Task { @MainActor in
            transcriptionText = ""
        }
    }
    
    // MARK: - Smart Engine Recommendations
    
    /// Get recommended engine based on environment conditions
    func getRecommendedEngine(for conditions: EnvironmentConditions) -> SpeechRecognitionMode {
        // Simple heuristic for now - can be enhanced with machine learning
        if conditions.noiseLevel < -40 && !conditions.musicDetected && !conditions.multipleSpeakers {
            return .fast // Quiet environment - use fast iOS Speech
        } else {
            return .professional // Noisy environment - use AssemblyAI
        }
    }
    
    /// Apply environment-based recommendation if user hasn't overridden
    func applyEnvironmentRecommendation(_ recommendation: SpeechRecognitionMode, force: Bool = false) async {
        guard force || shouldAcceptRecommendation(recommendation) else {
            return
        }
        
        print("🤖 Applying environment recommendation: \(recommendation.displayName)")
        await switchEngine(to: recommendation)
    }
    
    // MARK: - Private Implementation
    
    private func setupInitialEngine() {
        // Start with professional mode by default
        activeEngine = .professional
        bindToActiveEngine()
    }
    
    private func bindToActiveEngine() {
        // Clear existing subscriptions
        cancellables.removeAll()
        
        // Bind to current engine's published properties
        currentEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Mirror engine state properties
        mirrorEngineState()
        
        print("🔗 Bound to \(activeEngine.displayName) engine state")
    }
    
    private func mirrorEngineState() {
        Task { @MainActor in
            // Sync all state properties from current engine
            isRecording = currentEngine.isStreaming
            connectionState = currentEngine.connectionState
            errorMessage = currentEngine.errorMessage
            
            // Preserve accumulated text if switching mid-session
            if let preserved = preservedState?.accumulatedText, !preserved.isEmpty {
                let currentText = currentEngine.transcriptionText
                transcriptionText = currentText.isEmpty ? preserved : "\(preserved) \(currentText)"
            } else {
                transcriptionText = currentEngine.transcriptionText
            }
            
            // Update performance metrics
            updateEngineMetrics()
        }
    }
    
    private func updateEngineMetrics() {
        // Update current engine performance metrics
        if let metricsEngine = currentEngine as? SpeechEngineMetrics {
            currentEngineMetrics = EnginePerformanceMetrics(
                averageLatency: metricsEngine.averageLatency,
                accuracyScore: metricsEngine.accuracyScore,
                networkUsage: metricsEngine.networkUsage,
                batteryImpact: metricsEngine.batteryImpact
            )
        }
    }
    
    private func shouldAcceptRecommendation(_ recommendation: SpeechRecognitionMode) -> Bool {
        // Don't switch if already using recommended engine
        guard recommendation != activeEngine else { return false }
        
        // Don't switch during active recording unless critical
        guard !isRecording else { return false }
        
        // Don't switch too frequently (debounce)
        let timeSinceLastSwitch = sessionStats.lastSwitchTime.map { Date().timeIntervalSince($0) } ?? Double.infinity
        guard timeSinceLastSwitch > 10.0 else { return false }
        
        return true
    }
    
    private func trackEngineSwitch(successful: Bool) {
        sessionStats.recordEngineSwitch()
        
        if successful {
            print("📊 Engine switch successful - Total switches: \(sessionStats.engineSwitches)")
        } else {
            print("❌ Engine switch failed")
        }
    }
}

// MARK: - Performance Metrics

/// Performance metrics for the current engine
struct EnginePerformanceMetrics {
    let averageLatency: Double
    let accuracyScore: Double
    let networkUsage: Double
    let batteryImpact: EngineBatteryImpact
    
    init(averageLatency: Double = 0,
         accuracyScore: Double = 0,
         networkUsage: Double = 0,
         batteryImpact: EngineBatteryImpact = .low) {
        self.averageLatency = averageLatency
        self.accuracyScore = accuracyScore
        self.networkUsage = networkUsage
        self.batteryImpact = batteryImpact
    }
}

// MARK: - Environment Conditions

/// Environmental conditions for smart engine recommendations
struct EnvironmentConditions {
    let noiseLevel: Double          // dB level
    let musicDetected: Bool         // Background music present
    let multipleSpeakers: Bool      // Multiple voices detected
    let timestamp: Date
    
    init(noiseLevel: Double = -50, 
         musicDetected: Bool = false, 
         multipleSpeakers: Bool = false) {
        self.noiseLevel = noiseLevel
        self.musicDetected = musicDetected
        self.multipleSpeakers = multipleSpeakers
        self.timestamp = Date()
    }
}

// MARK: - Session Statistics

/// Track session and performance statistics
private class SessionStatistics {
    private(set) var engineSwitches: Int = 0
    private(set) var sessionStartTime: Date?
    private(set) var lastSwitchTime: Date?
    
    var currentSessionDuration: TimeInterval {
        sessionStartTime?.timeIntervalSinceNow.magnitude ?? 0
    }
    
    func startSession() {
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
    }
    
    func endSession() {
        // Keep session timing for potential resumption
    }
    
    func recordEngineSwitch() {
        engineSwitches += 1
        lastSwitchTime = Date()
    }
    
    func reset() {
        engineSwitches = 0
        sessionStartTime = nil
        lastSwitchTime = nil
    }
}

// MARK: - Engine Capabilities Extension

extension SpeechRecognitionManager {
    
    /// Get capabilities of the currently active engine
    var currentEngineCapabilities: SpeechEngineCapabilities? {
        return currentEngine as? SpeechEngineCapabilities
    }
    
    /// Check if current engine supports offline transcription
    var supportsOfflineTranscription: Bool {
        return currentEngineCapabilities?.supportsOfflineTranscription ?? false
    }
    
    /// Check if current engine requires network connection
    var requiresNetworkConnection: Bool {
        return currentEngineCapabilities?.requiresNetworkConnection ?? true
    }
}

// MARK: - Notification Support

extension SpeechRecognitionManager {
    
    /// Post notification for engine switch events
    private func postEngineChangeNotification() {
        NotificationCenter.default.post(
            name: .speechEngineDidChange,
            object: self,
            userInfo: ["engine": activeEngine.rawValue]
        )
    }
    
    /// Post notification for environment recommendations
    private func postEnvironmentRecommendationNotification(_ recommendation: SpeechRecognitionMode) {
        NotificationCenter.default.post(
            name: .environmentRecommendationUpdated,
            object: self,
            userInfo: [
                "recommendation": recommendation.rawValue,
                "current": activeEngine.rawValue
            ]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let speechEngineDidChange = Notification.Name("speechEngineDidChange")
    static let environmentRecommendationUpdated = Notification.Name("environmentRecommendationUpdated")
}