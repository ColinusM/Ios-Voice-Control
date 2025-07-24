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
    
    /// Voice command processor for generating RCP commands from transcription
    @Published var voiceCommandProcessor: VoiceCommandProcessor = VoiceCommandProcessor()
    
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
        print("🎛️ VoiceCommandProcessor initialized for real-time RCP command generation")
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
        }
        
        // Update performance metrics on main thread
        await MainActor.run {
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
        
        // Sync state after starting
        await refreshState()
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
        
        // Sync state after stopping
        Task {
            await refreshState()
        }
    }
    
    /// Clear all transcription text
    func clearTranscriptionText() {
        currentEngine.clearTranscriptionText()
        preservedState = nil
        sessionStats.reset()
        
        // Clear voice commands as well
        Task { @MainActor in
            voiceCommandProcessor.clearCommands()
        }
        
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
        
        // Mirror engine state properties immediately
        mirrorEngineState()
        
        // Set up continuous observation of engine state changes
        setupEngineStateObservation()
        
        print("🔗 Bound to \(activeEngine.displayName) engine state")
    }
    
    private func setupEngineStateObservation() {
        // Set up periodic state sync for real-time updates
        // Use a timer to regularly sync engine state changes
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncEngineStateIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func syncEngineStateIfNeeded() {
        // Check if transcription text has changed and sync if needed
        let currentEngineText = currentEngine.transcriptionText
        if transcriptionText != currentEngineText {
            syncTranscriptionText()
        }
        
        // Sync other state changes
        if isRecording != currentEngine.isStreaming ||
           connectionState != currentEngine.connectionState ||
           errorMessage != currentEngine.errorMessage {
            syncEngineState()
        }
    }
    
    private func syncTranscriptionText() {
        let previousText = transcriptionText
        
        // Preserve accumulated text if switching mid-session
        if let preserved = preservedState?.accumulatedText, !preserved.isEmpty {
            let currentText = currentEngine.transcriptionText
            transcriptionText = currentText.isEmpty ? preserved : "\(preserved) \(currentText)"
        } else {
            transcriptionText = currentEngine.transcriptionText
        }
        
        // Process transcription text for voice commands if it has changed
        if previousText != transcriptionText && !transcriptionText.isEmpty {
            processTranscriptionForVoiceCommands(transcriptionText)
        }
    }
    
    private func syncEngineState() {
        isRecording = currentEngine.isStreaming
        connectionState = currentEngine.connectionState
        errorMessage = currentEngine.errorMessage
        updateEngineMetrics()
    }
    
    private func mirrorEngineState() {
        // Sync all state properties from current engine (synchronous version)
        // All @Published property updates must happen on main thread
        Task { @MainActor in
            self.isRecording = self.currentEngine.isStreaming
            self.connectionState = self.currentEngine.connectionState
            self.errorMessage = self.currentEngine.errorMessage
            
            // Preserve accumulated text if switching mid-session
            if let preserved = self.preservedState?.accumulatedText, !preserved.isEmpty {
                let currentText = self.currentEngine.transcriptionText
                self.transcriptionText = currentText.isEmpty ? preserved : "\(preserved) \(currentText)"
            } else {
                self.transcriptionText = self.currentEngine.transcriptionText
            }
            
            // Update performance metrics
            self.updateEngineMetrics()
        }
    }
    
    /// Refresh state from current engine
    func refreshState() async {
        await MainActor.run {
            mirrorEngineState()
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
    
    // MARK: - Voice Command Processing
    
    /// Process transcription text through the voice command processor
    private func processTranscriptionForVoiceCommands(_ text: String) {
        // Only process during active recording to avoid stale processing
        guard isRecording else { return }
        
        // Convert spoken numbers to digits for low-latency processing
        let convertedText = convertSpokenNumbersToDigits(text)
        
        // Update the UI with converted text if it changed
        if convertedText != text {
            DispatchQueue.main.async { [weak self] in
                self?.transcriptionText = convertedText
            }
            print("📝 Number conversion for UI: \"\(text)\" → \"\(convertedText)\"")
        }
        
        // Process the converted text for voice commands
        voiceCommandProcessor.processTranscription(convertedText)
        
        print("🎛️ Processing transcription for voice commands: \"\(convertedText.prefix(50))\(convertedText.count > 50 ? "..." : "")\"")
    }
    
    /// Get the voice command processor for UI integration
    func getVoiceCommandProcessor() -> VoiceCommandProcessor {
        return voiceCommandProcessor
    }
    
    /// Convert spoken numbers to digits for low-latency voice command processing
    /// - Parameter text: Raw speech-to-text output with spoken numbers
    /// - Returns: Text with spoken numbers converted to digits
    private func convertSpokenNumbersToDigits(_ text: String) -> String {
        var processedText = text
        
        // Common spoken number mappings used in audio engineering
        let numberMappings: [(String, String)] = [
            // Single digits (most common in channel numbers)
            ("\\bone\\b", "1"),
            ("\\btwo\\b", "2"), 
            ("\\bthree\\b", "3"),
            ("\\bfour\\b", "4"),
            ("\\bfive\\b", "5"),
            ("\\bsix\\b", "6"),
            ("\\bseven\\b", "7"),
            ("\\beight\\b", "8"),
            ("\\bnine\\b", "9"),
            ("\\bten\\b", "10"),
            ("\\beleven\\b", "11"),
            ("\\btwelve\\b", "12"),
            ("\\bthirteen\\b", "13"),
            ("\\bfourteen\\b", "14"),
            ("\\bfifteen\\b", "15"),
            ("\\bsixteen\\b", "16"),
            ("\\bseventeen\\b", "17"),
            ("\\beighteen\\b", "18"),
            ("\\bnineteen\\b", "19"),
            ("\\btwenty\\b", "20"),
            
            // Teens and twenties (common in mixing boards)
            ("\\btwenty one\\b", "21"),
            ("\\btwenty two\\b", "22"),
            ("\\btwenty three\\b", "23"),
            ("\\btwenty four\\b", "24"),
            ("\\btwenty five\\b", "25"),
            ("\\btwenty six\\b", "26"),
            ("\\btwenty seven\\b", "27"),
            ("\\btwenty eight\\b", "28"),
            ("\\btwenty nine\\b", "29"),
            ("\\bthirty\\b", "30"),
            ("\\bthirty one\\b", "31"),
            ("\\bthirty two\\b", "32"),
            
            // Common negative values (dB levels)
            ("minus (\\w+)", "-$1"),
            ("negative (\\w+)", "-$1"),
            
            // Alternative pronunciations
            ("\\bzero\\b", "0"),
            ("\\boh\\b", "0"), // "oh" often used for "0"
        ]
        
        // Apply number conversions using regex
        for (spokenPattern, digitReplacement) in numberMappings {
            if let regex = try? NSRegularExpression(pattern: spokenPattern, options: [.caseInsensitive]) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(
                    in: processedText,
                    options: [],
                    range: range,
                    withTemplate: digitReplacement
                )
            }
        }
        
        // Clean up extra spaces
        processedText = processedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
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