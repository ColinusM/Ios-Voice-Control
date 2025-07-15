import Foundation
import Starscream

// MARK: - AssemblyAI WebSocket Streamer
class AssemblyAIStreamer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isStreaming: Bool = false
    @Published var transcriptionText: String = ""
    @Published var connectionState: StreamingState = .disconnected
    @Published var errorMessage: String?
    
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
    
    // MARK: - Public Methods
    
    func startStreaming() async {
        await MainActor.run {
            errorMessage = nil
            connectionState = .connecting
        }
        
        print("🚀 Starting AssemblyAI streaming...")
        
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
        print("🛑 Stopping AssemblyAI streaming...")
        
        // Stop audio recording
        audioManager.stopRecording()
        
        // Send session termination message
        if isConnected {
            sendSessionTermination()
        }
        
        // Disconnect WebSocket
        webSocket?.disconnect()
        webSocket = nil
        
        // Reset state
        Task { @MainActor in
            isStreaming = false
            connectionState = .disconnected
            sessionId = nil
            isConnected = false
            sessionBegun = false
            reconnectAttempts = 0
        }
        
        print("✅ AssemblyAI streaming stopped")
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
            print("📝 Transcript: \"\(turn.transcript)\" (end_of_turn: \(turn.end_of_turn ?? false))")
            
            Task { @MainActor in
                // Update transcription text in real-time
                let previousText = transcriptionText
                
                if turn.end_of_turn == true {
                    // Final transcript - add to accumulated text
                    if !transcriptionText.isEmpty {
                        transcriptionText += " "
                    }
                    transcriptionText += turn.transcript
                    print("📝 Final transcript updated: '\(previousText)' -> '\(transcriptionText)'")
                } else {
                    // Partial transcript - show in real-time but don't accumulate yet
                    // For now, we'll accumulate everything for simplicity
                    if !transcriptionText.isEmpty && !transcriptionText.hasSuffix(" ") {
                        transcriptionText += " "
                    }
                    transcriptionText += turn.transcript
                    print("📝 Partial transcript updated: '\(previousText)' -> '\(transcriptionText)'")
                }
                
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
        connectionState = .error(error.localizedDescription)
        
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
                if connectionState != .error("") { // Don't override error state
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
}