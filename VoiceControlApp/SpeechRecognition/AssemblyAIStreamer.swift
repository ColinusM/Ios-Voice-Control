import Foundation
import Starscream

// MARK: - AssemblyAI WebSocket Streamer
class AssemblyAIStreamer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isStreaming: Bool = false
    @Published var transcriptionText: String = ""
    @Published var connectionState: StreamingState = .disconnected
    @Published var errorMessage: String?
    
    // MARK: - Private Transcription State
    private var accumulatedText: String = "" // Final completed turns
    private var currentTurnText: String = "" // Current partial turn
    
    // MARK: - Private Properties
    private var webSocket: WebSocket?
    private var audioManager = AudioManager()
    private let config = StreamingConfig.shared
    
    // State management
    private var sessionId: String?
    private var reconnectAttempts = 0
    private var isConnected = false
    private var sessionBegun = false // Track if we've received SessionBegins
    private var chunkCount = 0
    private var lastWords: [TranscriptWord] = [] // Track latest words for immediate extraction
    
    // MARK: - Usage Tracking
    private var sessionStartTime: Date?
    private var totalSessionMinutes: Int = 0
    private weak var subscriptionManager: SubscriptionManager?
    private weak var authManager: AuthenticationManager?
    
    // MARK: - Public Methods
    
    /// Configure managers for usage tracking and subscription validation
    func configure(subscriptionManager: SubscriptionManager, authManager: AuthenticationManager) {
        self.subscriptionManager = subscriptionManager
        self.authManager = authManager
    }
    
    func clearTranscriptionText() {
        Task { @MainActor in
            accumulatedText = ""
            currentTurnText = ""
            transcriptionText = ""
        }
    }
    
    func startStreaming() async {
        // MARK: - Usage Validation and Gating
        
        // Check if user can access API (subscription or guest limits)
        guard await canStartStreaming() else {
            await MainActor.run {
                errorMessage = "API usage limit reached. Please upgrade to Voice Control Pro for unlimited access."
                connectionState = .error(.usageLimitReached)
            }
            return
        }
        
        await MainActor.run {
            errorMessage = nil
            connectionState = .connecting
            // Don't clear accumulated text when starting a new session
            // Only clear current turn text
            currentTurnText = ""
        }
        
        print("🚀 Starting AssemblyAI streaming...")
        
        // Start session timing
        sessionStartTime = Date()
        
        do {
            // Setup WebSocket connection
            try await setupWebSocketConnection()
            
            // Start audio capture and streaming
            try await audioManager.startRecording { [weak self] audioData in
                self?.streamAudioData(audioData)
            }
            
            await MainActor.run {
                self.isStreaming = true
                self.connectionState = .streaming
                print("🎯 Stream state updated: isStreaming=\(self.isStreaming), isConnected=\(self.isConnected)")
            }
            
            print("✅ AssemblyAI streaming started successfully")
            
        } catch {
            await handleStreamingError(error)
        }
    }
    
    func stopStreaming() {
        print("🛑 Stopping streaming immediately...")
        
        // Track usage before stopping
        trackSessionUsage()
        
        // Stop audio recording immediately
        audioManager.stopRecording()
        
        // Extract any remaining words immediately before cleanup
        Task { @MainActor in
            // Extract complete words if available
            if !lastWords.isEmpty {
                let wordsText = lastWords.map { $0.text }.joined(separator: " ")
                print("📝 Extracting final words: '\(wordsText)'")
                
                // Replace current partial text with complete words
                if !wordsText.isEmpty {
                    if !accumulatedText.isEmpty {
                        accumulatedText += " "
                    }
                    accumulatedText += wordsText
                    currentTurnText = ""
                    transcriptionText = accumulatedText
                    print("📝 Final transcript with extracted words: '\(accumulatedText)'")
                }
            } else if !currentTurnText.isEmpty {
                // Fallback: preserve partial transcript if no words available
                if !accumulatedText.isEmpty {
                    accumulatedText += " "
                }
                accumulatedText += currentTurnText
                currentTurnText = ""
                transcriptionText = accumulatedText
                print("📝 Preserved partial transcript: '\(accumulatedText)'")
            }
            
            // Immediate cleanup - no waiting
            isStreaming = false
            connectionState = .disconnected
        }
        
        // Send session termination and disconnect immediately
        if isConnected {
            sendSessionTermination()
        }
        
        webSocket?.disconnect()
        webSocket = nil
        
        // Reset all state
        Task { @MainActor in
            sessionId = nil
            isConnected = false
            sessionBegun = false
            reconnectAttempts = 0
            lastWords = []
        }
        
        print("✅ AssemblyAI streaming stopped immediately")
    }
    
    // MARK: - Private Methods
    
    private func setupWebSocketConnection() async throws {
        print("🔌 Setting up WebSocket connection...")
        
        // Build WebSocket URL with query parameters for AssemblyAI v3 API
        var urlComponents = URLComponents(string: config.websocketEndpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "sample_rate", value: String(config.sampleRate)),
            URLQueryItem(name: "encoding", value: config.encoding),
            URLQueryItem(name: "format_turns", value: String(config.formatTurns)),
            URLQueryItem(name: "end_of_turn_confidence_threshold", value: String(config.endOfTurnConfidenceThreshold)),
            URLQueryItem(name: "min_end_of_turn_silence_when_confident", value: String(config.minEndOfTurnSilenceWhenConfident)),
            URLQueryItem(name: "max_turn_silence", value: String(config.maxTurnSilence)),
            URLQueryItem(name: "language", value: config.language)
        ]
        
        guard let finalURL = urlComponents.url else {
            throw AudioStreamError.webSocketConnectionFailed("Failed to construct WebSocket URL with parameters")
        }
        
        print("🔗 Connecting to: \(finalURL)")
        
        // Create WebSocket request with API key authentication
        var request = URLRequest(url: finalURL)
        // Clean the API key and ensure proper format
        let cleanApiKey = config.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        request.setValue(cleanApiKey, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = config.connectionTimeout
        
        // Create WebSocket
        webSocket = WebSocket(request: request)
        webSocket?.delegate = self
        
        // Connect
        webSocket?.connect()
        
        // Wait for connection (with timeout)
        let connectionResult = await withCheckedContinuation { continuation in
            var hasResumed = false
            
            // Success case
            let successHandler = {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: true)
                }
            }
            
            // Timeout case
            Task {
                try? await Task.sleep(nanoseconds: UInt64(config.connectionTimeout * 1_000_000_000))
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: false)
                }
            }
            
            // Store success handler for delegate callback
            self.connectionSuccessHandler = successHandler
        }
        
        guard connectionResult else {
            throw AudioStreamError.webSocketConnectionFailed("Connection timeout")
        }
        
        print("✅ WebSocket connected successfully")
    }
    
    private var connectionSuccessHandler: (() -> Void)?
    
    // AssemblyAI v3 API: Session begin message not needed - configuration sent via query parameters
    
    private func sendSessionTermination() {
        print("📡 Sending session termination message...")
        
        let termination = SessionTerminationMessage()
        
        do {
            let data = try JSONEncoder().encode(termination)
            webSocket?.write(data: data)
            print("✅ Session termination message sent")
        } catch {
            print("❌ Failed to send session termination: \(error)")
        }
    }
    
    private func streamAudioData(_ audioData: Data) {
        guard isConnected && isStreaming && sessionBegun else { 
            print("⚠️ Not streaming audio: connected=\(isConnected), streaming=\(isStreaming), sessionBegun=\(sessionBegun)")
            return 
        }
        
        // Send binary audio data directly to WebSocket
        webSocket?.write(data: audioData)
        
        // Debug logging (every 10 chunks for more frequent updates)
        chunkCount += 1
        if chunkCount % 10 == 0 {
            print("📡 Sent audio chunk \(chunkCount): \(audioData.count) bytes")
        }
        
        // Debug first chunk
        if chunkCount == 1 {
            print("🎵 First audio chunk sent: \(audioData.count) bytes")
        }
    }
    
    private func handleIncomingMessage(_ data: Data) {
        // Debug: Print raw message for troubleshooting
        if let rawString = String(data: data, encoding: .utf8) {
            print("📨 Raw AssemblyAI message: \(rawString)")
        }
        
        guard let response = AssemblyAIResponse(from: data) else {
            print("⚠️ Failed to parse AssemblyAI response")
            return
        }
        
        switch response {
        case .sessionBegins(let sessionBegins):
            // AssemblyAI v3 API: Session begins not used, but keeping for compatibility
            print("🎯 Session begins: \(sessionBegins.session_id)")
            sessionId = sessionBegins.session_id
            
        case .turn(let turn):
            print("📝 Transcript: \"\(turn.transcript)\" (end_of_turn: \(turn.end_of_turn ?? false), formatted: \(turn.turn_is_formatted ?? false))")
            
            // Capture latest words for immediate extraction on stop
            if let words = turn.words, !words.isEmpty {
                lastWords = words
                print("📝 Captured \(words.count) words for immediate extraction")
            }
            
            Task { @MainActor in
                if turn.end_of_turn == true {
                    // Final transcript - use words array if available, fallback to transcript
                    let finalText = !lastWords.isEmpty ? lastWords.map { $0.text }.joined(separator: " ") : turn.transcript
                    if !finalText.isEmpty {
                        if !accumulatedText.isEmpty {
                            accumulatedText += " "
                        }
                        accumulatedText += finalText
                    }
                    currentTurnText = ""
                    print("📝 Final transcript from words: '\(finalText)' -> Total: '\(accumulatedText)'")
                } else {
                    // Partial transcript - use words array for immediate display of all detected words
                    if !lastWords.isEmpty {
                        currentTurnText = lastWords.map { $0.text }.joined(separator: " ")
                        print("📝 Partial from words: '\(currentTurnText)' (showing \(lastWords.count) words)")
                    } else {
                        currentTurnText = turn.transcript
                        print("📝 Partial from transcript: '\(turn.transcript)'")
                    }
                }
                
                // Update displayed text: accumulated + current turn
                let newDisplayText = accumulatedText + (currentTurnText.isEmpty ? "" : (accumulatedText.isEmpty ? "" : " ") + currentTurnText)
                transcriptionText = newDisplayText
                
                // Force UI update
                objectWillChange.send()
            }
            
        case .sessionTerminates(let termination):
            print("🏁 Session terminated: \(termination.audio_duration_seconds ?? 0) seconds processed")
            
        case .error(let error):
            print("❌ AssemblyAI error: \(error.error)")
            Task {
                await handleStreamingError(AudioStreamError.webSocketConnectionFailed(error.error))
            }
        }
    }
    
    @MainActor
    private func handleStreamingError(_ error: Error) {
        print("❌ Streaming error: \(error)")
        
        errorMessage = error.localizedDescription
        
        // Convert error to appropriate StreamingError
        let streamingError: StreamingError
        if let audioStreamError = error as? AudioStreamError {
            switch audioStreamError {
            case .permissionDenied:
                streamingError = .authenticationFailed
            case .webSocketConnectionFailed:
                streamingError = .connectionFailed(error.localizedDescription)
            case .audioEngineFailure:
                streamingError = .unknownError(error.localizedDescription)
            case .audioFormatNotSupported, .microphoneUnavailable:
                streamingError = .unknownError(error.localizedDescription)
            }
        } else {
            streamingError = .unknownError(error.localizedDescription)
        }
        
        connectionState = .error(streamingError)
        
        // Stop streaming on error
        if isStreaming {
            Task {
                stopStreaming()
            }
        }
        
        // Attempt reconnection if not too many attempts
        if reconnectAttempts < config.maxReconnectAttempts {
            reconnectAttempts += 1
            print("🔄 Attempting reconnection \(reconnectAttempts)/\(config.maxReconnectAttempts)")
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                await startStreaming()
            }
        }
    }
}

// MARK: - WebSocket Delegate
extension AssemblyAIStreamer: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            print("✅ WebSocket connected with headers: \(headers)")
            isConnected = true
            sessionBegun = true // v3 API: ready to stream immediately after connection
            reconnectAttempts = 0
            
            Task { @MainActor in
                connectionState = .connected
            }
            
            // AssemblyAI v3 API: Configuration sent via query parameters, ready to stream immediately
            print("🎯 AssemblyAI v3 connection established - ready to stream audio")
            
            // Call success handler if waiting
            connectionSuccessHandler?()
            connectionSuccessHandler = nil
            
        case .disconnected(let reason, let code):
            print("🔌 WebSocket disconnected: \(reason) (code: \(code))")
            isConnected = false
            sessionBegun = false
            
            Task { @MainActor in
                // Don't override error state - only set to disconnected if not in error
                if case .error = connectionState {
                    // Keep error state
                } else {
                    connectionState = .disconnected
                }
            }
            
        case .text(let string):
            print("📨 WebSocket text message: \(string)")
            if let data = string.data(using: .utf8) {
                handleIncomingMessage(data)
            }
            
        case .binary(let data):
            print("📨 WebSocket binary message: \(data.count) bytes")
            handleIncomingMessage(data)
            
        case .ping(_):
            print("🏓 WebSocket ping received")
            
        case .pong(_):
            print("🏓 WebSocket pong received")
            
        case .viabilityChanged(let isViable):
            print("🔗 WebSocket viability changed: \(isViable)")
            
        case .reconnectSuggested(let shouldReconnect):
            print("🔄 WebSocket reconnect suggested: \(shouldReconnect)")
            if shouldReconnect && reconnectAttempts < config.maxReconnectAttempts {
                Task {
                    await handleStreamingError(AudioStreamError.webSocketConnectionFailed("Reconnection suggested"))
                }
            }
            
        case .cancelled:
            print("❌ WebSocket cancelled")
            isConnected = false
            sessionBegun = false
            
        case .error(let error):
            print("❌ WebSocket error: \(error?.localizedDescription ?? "Unknown error")")
            let errorMsg = error?.localizedDescription ?? "WebSocket connection error"
            Task {
                await handleStreamingError(AudioStreamError.webSocketConnectionFailed(errorMsg))
            }
            
        case .peerClosed:
            print("🔌 WebSocket peer closed connection")
            isConnected = false
            sessionBegun = false
            Task { @MainActor in
                connectionState = .disconnected
            }
        }
    }
    
    // MARK: - Usage Tracking and Gating
    
    /// Check if user can start streaming based on subscription status and usage limits
    private func canStartStreaming() async -> Bool {
        guard let subscriptionManager = subscriptionManager,
              let _ = authManager else {
            // If managers not configured, allow streaming (fallback)
            print("⚠️ AssemblyAIStreamer: Managers not configured, allowing streaming")
            return true
        }
        
        // Check subscription state
        switch subscriptionManager.subscriptionState {
        case .premium:
            // Premium users have unlimited access
            print("✅ Premium user - unlimited API access")
            return true
            
        case .free(let remainingMinutes):
            // Free/guest users have limited access
            if remainingMinutes > 0 {
                print("✅ Guest user - \(remainingMinutes) minutes remaining")
                return true
            } else {
                print("❌ Guest user - usage limit exceeded")
                return false
            }
            
        case .expired:
            print("❌ Subscription expired")
            return false
            
        case .loading, .unknown:
            // Allow streaming while checking subscription status
            print("⚠️ Subscription status loading - allowing streaming")
            return true
            
        case .error:
            // Allow streaming on subscription check errors (graceful fallback)
            print("⚠️ Subscription check error - allowing streaming")
            return true
        }
    }
    
    /// Track usage when session ends
    private func trackSessionUsage() {
        guard let sessionStartTime = sessionStartTime else {
            print("⚠️ No session start time recorded")
            return
        }
        
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        let sessionMinutes = max(1, Int(ceil(sessionDuration / 60.0))) // Round up, minimum 1 minute
        
        print("📊 Session ended - Duration: \(String(format: "%.1f", sessionDuration))s (\(sessionMinutes) minutes)")
        
        // Reset session timing
        self.sessionStartTime = nil
        
        // Update usage tracking
        Task { @MainActor in
            await updateUsageTracking(sessionMinutes: sessionMinutes)
        }
    }
    
    /// Update usage tracking for both subscription manager and auth manager
    @MainActor
    private func updateUsageTracking(sessionMinutes: Int) async {
        // Update subscription manager usage
        await subscriptionManager?.updateAPIUsage(minutesUsed: sessionMinutes)
        
        // Update guest user usage if in guest mode
        if let authManager = authManager, authManager.authState == .guest {
            authManager.updateGuestUsage(minutesUsed: sessionMinutes)
        }
        
        print("📊 Usage updated - \(sessionMinutes) minutes tracked")
    }
    
}