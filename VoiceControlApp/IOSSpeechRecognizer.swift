import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - iOS Speech Framework Integration

/// iOS Speech Framework implementation for fast, low-latency speech recognition
/// Supports both on-device and server-based recognition with automatic fallback
class IOSSpeechRecognizer: NSObject, SpeechRecognitionEngine, ObservableObject {
    
    // MARK: - Published Properties (Protocol Conformance)
    
    @Published var isStreaming: Bool = false
    @Published var transcriptionText: String = ""
    @Published var connectionState: StreamingState = .disconnected
    @Published var errorMessage: String?
    
    // MARK: - iOS Speech Framework Properties
    
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - State Management
    
    private var accumulatedText: String = ""
    private var currentPartialText: String = ""
    private var sessionStartTime: Date?
    private var isConfigured = false
    
    // MARK: - Configuration & Dependencies
    
    private weak var subscriptionManager: SubscriptionManager?
    private weak var authManager: AuthenticationManager?
    private let locale: Locale
    private let preferOnDevice: Bool
    
    // MARK: - Performance Tracking
    
    private var recognitionStartTime: Date?
    private var totalWords: Int = 0
    private var averageLatencyMs: Double = 0
    
    // MARK: - Initialization
    
    init(locale: Locale = Locale.current, preferOnDevice: Bool = true) {
        self.locale = locale
        self.preferOnDevice = preferOnDevice
        
        // Initialize speech recognizer for the specified locale
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            fatalError("Speech recognizer not available for locale: \(locale.identifier)")
        }
        
        self.speechRecognizer = recognizer
        super.init()
        
        // Configure speech recognizer delegate
        speechRecognizer.delegate = self
        
        print("🎤 IOSSpeechRecognizer initialized - Locale: \(locale.identifier), On-device preferred: \(preferOnDevice)")
    }
    
    // MARK: - Protocol Implementation
    
    func configure(subscriptionManager: SubscriptionManager, authManager: AuthenticationManager) {
        self.subscriptionManager = subscriptionManager
        self.authManager = authManager
        self.isConfigured = true
        print("✅ IOSSpeechRecognizer configured with subscription and auth managers")
    }
    
    func clearTranscriptionText() {
        Task { @MainActor in
            accumulatedText = ""
            currentPartialText = ""
            transcriptionText = ""
            totalWords = 0
        }
    }
    
    func startStreaming() async {
        print("🚀 Starting iOS Speech recognition...")
        
        // Validate configuration
        guard isConfigured else {
            await handleError(IOSSpeechError.notConfigured)
            return
        }
        
        // Check permissions
        guard await requestAllPermissions() else {
            await handleError(IOSSpeechError.permissionDenied)
            return
        }
        
        // Check speech recognizer availability
        guard speechRecognizer.isAvailable else {
            await handleError(IOSSpeechError.recognizerUnavailable)
            return
        }
        
        await MainActor.run {
            errorMessage = nil
            connectionState = .connecting
            currentPartialText = ""
        }
        
        sessionStartTime = Date()
        recognitionStartTime = Date()
        
        do {
            // Setup audio session
            try await configureAudioSession()
            
            // Setup recognition request
            try setupRecognitionRequest()
            
            // Setup audio engine
            try setupAudioEngine()
            
            // Start recognition task
            try startRecognitionTask()
            
            // Start audio engine
            try audioEngine.start()
            
            await MainActor.run {
                self.isStreaming = true
                self.connectionState = .streaming
            }
            
            print("✅ iOS Speech recognition started successfully")
            
        } catch {
            await handleError(error)
        }
    }
    
    func stopStreaming() {
        print("🛑 Stopping iOS Speech recognition...")
        
        // Track session usage
        trackSessionUsage()
        
        // Stop audio engine immediately
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Finalize recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Preserve any accumulated text
        Task { @MainActor in
            // Preserve partial text if available
            if !currentPartialText.isEmpty {
                if !accumulatedText.isEmpty {
                    accumulatedText += " "
                }
                accumulatedText += currentPartialText
                currentPartialText = ""
                transcriptionText = accumulatedText
            }
            
            // Update state
            isStreaming = false
            connectionState = .disconnected
        }
        
        // Cleanup
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session
        deactivateAudioSession()
        
        print("✅ iOS Speech recognition stopped")
    }
    
    // MARK: - Private Implementation
    
    private func requestAllPermissions() async -> Bool {
        // Request microphone permission
        let micPermission = await requestMicrophonePermission()
        guard micPermission else {
            print("❌ Microphone permission denied")
            return false
        }
        
        // Request speech recognition permission
        let speechPermission = await requestSpeechRecognitionPermission()
        guard speechPermission else {
            print("❌ Speech recognition permission denied")
            return false
        }
        
        return true
    }
    
    private func requestMicrophonePermission() async -> Bool {
        let audioManager = AudioManager()
        return await audioManager.requestMicrophonePermission()
    }
    
    private func requestSpeechRecognitionPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("🎤 Speech recognition permission granted")
                    continuation.resume(returning: true)
                case .denied, .restricted, .notDetermined:
                    print("❌ Speech recognition permission denied: \(status)")
                    continuation.resume(returning: false)
                @unknown default:
                    print("❌ Unknown speech recognition permission status")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func configureAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .measurement, 
                                       options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            print("✅ Audio session configured for iOS Speech recognition")
        } catch {
            print("❌ Audio session configuration failed: \(error)")
            throw IOSSpeechError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    private func setupRecognitionRequest() throws {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw IOSSpeechError.recognitionRequestFailed
        }
        
        // Configure recognition request
        recognitionRequest.shouldReportPartialResults = true
        
        // Prefer on-device recognition if available and requested
        if preferOnDevice && speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
            print("🎯 Using on-device speech recognition")
        } else {
            recognitionRequest.requiresOnDeviceRecognition = false
            print("🌐 Using server-based speech recognition")
        }
        
        // Set task hint for optimal performance
        if #available(iOS 13.0, *) {
            recognitionRequest.taskHint = .dictation
        }
    }
    
    private func setupAudioEngine() throws {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate format
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            throw IOSSpeechError.audioFormatInvalid
        }
        
        print("🎵 iOS Speech audio format: \(inputFormat)")
        
        // Install audio tap for real-time processing
        inputNode.installTap(onBus: 0, 
                           bufferSize: 4096, 
                           format: inputFormat) { [weak self] buffer, time in
            
            // Send audio buffer to recognition request
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
    }
    
    private func startRecognitionTask() throws {
        guard let recognitionRequest = recognitionRequest else {
            throw IOSSpeechError.recognitionRequestFailed
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                await self?.handleRecognitionResult(result: result, error: error)
            }
        }
    }
    
    @MainActor
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) async {
        var isFinal = false
        
        if let result = result {
            let newText = result.bestTranscription.formattedString
            isFinal = result.isFinal
            
            // Calculate performance metrics
            if let startTime = recognitionStartTime {
                let latency = Date().timeIntervalSince(startTime) * 1000 // ms
                updateLatencyMetrics(latency: latency)
            }
            
            if isFinal {
                // Final result - move to accumulated text
                if !newText.isEmpty {
                    if !accumulatedText.isEmpty {
                        accumulatedText += " "
                    }
                    accumulatedText += newText
                    totalWords += newText.split(separator: " ").count
                }
                currentPartialText = ""
                
                print("📝 iOS Speech final result: '\(newText)' -> Total: '\(accumulatedText)'")
            } else {
                // Partial result - update current partial text
                currentPartialText = newText
                print("📝 iOS Speech partial result: '\(newText)'")
            }
            
            // Update displayed text: accumulated + current partial
            let displayText = accumulatedText + (currentPartialText.isEmpty ? "" : (accumulatedText.isEmpty ? "" : " ") + currentPartialText)
            transcriptionText = displayText
            
            // Reset recognition start time for next segment
            if isFinal {
                recognitionStartTime = Date()
            }
        }
        
        if let error = error {
            await handleError(error)
        }
        
        // If final result or error, the task is complete
        if isFinal || error != nil {
            recognitionTask = nil
        }
    }
    
    private func updateLatencyMetrics(latency: Double) {
        // Update running average of latency
        if averageLatencyMs == 0 {
            averageLatencyMs = latency
        } else {
            averageLatencyMs = (averageLatencyMs * 0.8) + (latency * 0.2)
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("✅ Audio session deactivated")
        } catch {
            print("⚠️ Error deactivating audio session: \(error)")
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) async {
        print("❌ iOS Speech error: \(error)")
        
        let friendlyMessage: String
        let streamingError: StreamingError
        
        if let iosSpeechError = error as? IOSSpeechError {
            friendlyMessage = iosSpeechError.localizedDescription
            streamingError = iosSpeechError.streamingError
        } else if let speechError = error as? NSError {
            switch speechError.code {
            case 201: // Speech recognition not available
                friendlyMessage = "Speech recognition is not available on this device"
                streamingError = .unknownError("Recognition unavailable")
            case 203: // Recognition request cancelled
                friendlyMessage = "Speech recognition was cancelled"
                streamingError = .connectionFailed("Recognition cancelled")
            default:
                friendlyMessage = "Speech recognition error: \(speechError.localizedDescription)"
                streamingError = .unknownError(speechError.localizedDescription)
            }
        } else {
            friendlyMessage = error.localizedDescription
            streamingError = .unknownError(error.localizedDescription)
        }
        
        errorMessage = friendlyMessage
        connectionState = .error(streamingError)
        
        // Stop streaming on error
        if isStreaming {
            stopStreaming()
        }
    }
    
    // MARK: - Usage Tracking
    
    private func trackSessionUsage() {
        guard let sessionStartTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let sessionMinutes = max(1, Int(ceil(sessionDuration / 60.0)))
        
        print("📊 iOS Speech session ended - Duration: \(String(format: "%.1f", sessionDuration))s (\(sessionMinutes) minutes)")
        print("📊 Performance - Words: \(totalWords), Avg Latency: \(String(format: "%.1f", averageLatencyMs))ms")
        
        // Reset session timing
        self.sessionStartTime = nil
        
        // Note: iOS Speech Framework usage is typically free for reasonable usage
        // Could implement usage tracking here if needed for analytics
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension IOSSpeechRecognizer: SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available && isStreaming {
                await handleError(IOSSpeechError.recognizerUnavailable)
            }
        }
    }
}

// MARK: - iOS Speech Specific Errors

enum IOSSpeechError: LocalizedError {
    case notConfigured
    case permissionDenied
    case recognizerUnavailable
    case recognitionRequestFailed
    case audioSessionFailed(String)
    case audioFormatInvalid
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Speech recognizer not configured. Please configure with subscription and auth managers."
        case .permissionDenied:
            return "Speech recognition permission denied. Please enable microphone and speech recognition access in Settings."
        case .recognizerUnavailable:
            return "Speech recognition is not available. Please check your device settings and network connection."
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request."
        case .audioSessionFailed(let message):
            return "Audio session configuration failed: \(message)"
        case .audioFormatInvalid:
            return "Invalid audio format for speech recognition."
        case .recognitionFailed(let message):
            return "Speech recognition failed: \(message)"
        }
    }
    
    var streamingError: StreamingError {
        switch self {
        case .notConfigured, .recognitionRequestFailed, .audioFormatInvalid:
            return .unknownError(localizedDescription ?? "Unknown error")
        case .permissionDenied:
            return .authenticationFailed
        case .recognizerUnavailable, .audioSessionFailed, .recognitionFailed:
            return .connectionFailed(localizedDescription ?? "Connection failed")
        }
    }
}

// MARK: - Capabilities Extension

extension IOSSpeechRecognizer: SpeechEngineCapabilities {
    
    var supportsOfflineTranscription: Bool {
        return speechRecognizer.supportsOnDeviceRecognition
    }
    
    var supportsRealTimeStreaming: Bool {
        return true
    }
    
    var requiresNetworkConnection: Bool {
        return !preferOnDevice || !speechRecognizer.supportsOnDeviceRecognition
    }
    
    var maxAudioDuration: TimeInterval? {
        // iOS Speech Framework has a 1-minute limit per recognition request
        return 60.0
    }
    
    var supportedLanguages: [String] {
        return SFSpeechRecognizer.supportedLocales().map { $0.identifier }
    }
}

// MARK: - Metrics Extension

extension IOSSpeechRecognizer: SpeechEngineMetrics {
    
    var averageLatency: Double {
        return averageLatencyMs
    }
    
    var accuracyScore: Double {
        // iOS Speech Framework doesn't provide direct accuracy scores
        // Return estimated score based on engine type
        return supportsOfflineTranscription ? 0.85 : 0.90
    }
    
    var networkUsage: Double {
        // Estimate network usage - on-device uses ~0, server-based uses ~1KB/s
        return requiresNetworkConnection ? 1024.0 : 0.0
    }
    
    var batteryImpact: EngineBatteryImpact {
        return supportsOfflineTranscription ? .low : .medium
    }
}