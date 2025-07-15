import Foundation
import AVFoundation

// MARK: - Audio Manager for Real-time Capture
class AudioManager: NSObject {
    
    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioCallback: ((Data) -> Void)?
    private let config = StreamingConfig.shared
    
    // Audio session configuration
    private let audioSession = AVAudioSession.sharedInstance()
    
    // State tracking
    private(set) var isRecording = false
    private var chunkCount = 0
    
    // MARK: - Permission Management
    func requestMicrophonePermission() async -> Bool {
        print("🎤 Requesting microphone permission...")
        
        // First check current permission status
        let currentStatus = audioSession.recordPermission
        print("🎤 Current permission status: \(currentStatus.rawValue)")
        
        switch currentStatus {
        case .granted:
            print("🎤 Permission already granted")
            return true
        case .denied:
            print("🎤 Permission denied - user needs to enable in Settings")
            return false
        case .undetermined:
            print("🎤 Permission undetermined - requesting now...")
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    print("🎤 Permission request result: \(granted ? "Granted" : "Denied")")
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            print("🎤 Unknown permission status")
            return false
        }
    }
    
    func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return audioSession.recordPermission
    }
    
    // MARK: - Audio Recording Management
    func startRecording(audioCallback: @escaping (Data) -> Void) async throws {
        print("🎤 Starting audio recording...")
        
        // Check permission first
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw AudioStreamError.permissionDenied
        }
        
        // Store callback
        self.audioCallback = audioCallback
        
        // Configure audio session
        try await configureAudioSession()
        
        // Small delay to ensure audio session is fully established
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Setup audio engine
        try setupAudioEngine()
        
        // Start the engine
        try audioEngine?.start()
        isRecording = true
        
        print("✅ Audio recording started successfully")
    }
    
    func stopRecording() {
        print("🛑 Stopping audio recording...")
        
        // Stop and cleanup audio engine
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        audioCallback = nil
        isRecording = false
        
        // Deactivate audio session
        do {
            try audioSession.setActive(false)
            print("✅ Audio session deactivated")
        } catch {
            print("⚠️ Error deactivating audio session: \(error)")
        }
        
        print("✅ Audio recording stopped")
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() async throws {
        do {
            // Configure audio session for recording
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default, 
                                       options: [.defaultToSpeaker, .allowBluetooth])
            
            // Set preferred IO buffer duration for low latency
            try audioSession.setPreferredIOBufferDuration(config.chunkDuration)
            
            // Activate the session FIRST before setting sample rate
            try audioSession.setActive(true)
            
            // Now set preferred sample rate after session is active
            try audioSession.setPreferredSampleRate(Double(config.sampleRate))
            
            print("✅ Audio session configured - Sample rate: \(audioSession.sampleRate)Hz")
            
        } catch {
            print("❌ Audio session configuration failed: \(error)")
            throw AudioStreamError.audioEngineFailure("Session configuration failed: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw AudioStreamError.audioEngineFailure("Failed to create audio engine")
        }
        
        inputNode = audioEngine.inputNode
        
        guard let inputNode = inputNode else {
            throw AudioStreamError.microphoneUnavailable
        }
        
        // MUST use the hardware's actual format - no custom format allowed
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Validate the format has valid parameters
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            throw AudioStreamError.audioEngineFailure("Invalid hardware format: \(inputFormat)")
        }
        
        print("🎵 Input format: \(inputFormat)")
        print("🎵 Session sample rate: \(audioSession.sampleRate)Hz, channels: \(audioSession.inputNumberOfChannels)")
        
        // Install audio tap for real-time capture using the created format
        inputNode.installTap(onBus: 0, 
                           bufferSize: config.bufferSize, 
                           format: inputFormat) { [weak self] buffer, time in
            
            // Convert AVAudioPCMBuffer to Data
            guard let audioData = self?.convertBufferToData(buffer) else { return }
            
            // Send audio data via callback
            self?.audioCallback?(audioData)
        }
        
        // Prepare the engine
        audioEngine.prepare()
        
        print("✅ Audio engine setup complete")
    }
    
    // MARK: - Audio Downsampling
    private func downsample(input: [Float], fromRate: Double, toRate: Double) -> [Float] {
        guard fromRate > toRate else { return input }
        
        let ratio = fromRate / toRate
        let outputLength = Int(Double(input.count) / ratio)
        var output = [Float]()
        output.reserveCapacity(outputLength)
        
        for i in 0..<outputLength {
            let inputIndex = Int(Double(i) * ratio)
            if inputIndex < input.count {
                output.append(input[inputIndex])
            }
        }
        
        return output
    }
    
    private func convertBufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        // Handle different audio formats (float32 is more common on iOS)
        if let floatChannelData = buffer.floatChannelData {
            let channelDataValue = floatChannelData.pointee
            let frameLength = Int(buffer.frameLength)
            
            // Get the actual sample rate of the input
            let inputSampleRate = buffer.format.sampleRate
            let targetSampleRate = Double(config.sampleRate) // 16000 Hz
            
            // Downsample if necessary (44.1kHz/48kHz → 16kHz)
            let downsampledData: [Float]
            if inputSampleRate > targetSampleRate {
                let inputArray = Array(UnsafeBufferPointer(start: channelDataValue, count: frameLength))
                downsampledData = downsample(input: inputArray, fromRate: inputSampleRate, toRate: targetSampleRate)
                
                // Debug logging for first few chunks
                if chunkCount < 3 {
                    print("🔄 Downsampling: \(inputSampleRate)Hz → \(targetSampleRate)Hz, \(frameLength) → \(downsampledData.count) samples")
                }
            } else {
                downsampledData = Array(UnsafeBufferPointer(start: channelDataValue, count: frameLength))
            }
            
            // Convert float32 to int16 for AssemblyAI
            let int16Array = downsampledData.map { sample -> Int16 in
                // Convert from float (-1.0 to 1.0) to int16 (-32768 to 32767)
                return Int16(max(-32768, min(32767, sample * 32767)))
            }
            
            let data = Data(bytes: int16Array, count: int16Array.count * MemoryLayout<Int16>.size)
            
            // Debug: Print data info every 100 chunks
            chunkCount += 1
            if chunkCount % 100 == 0 {
                print("📊 Audio chunk \(chunkCount): \(data.count) bytes, \(buffer.frameLength) frames → \(downsampledData.count) downsampled")
            }
            
            return data
        }
        
        // Fallback for int16 data (less common but still supported)
        else if let int16ChannelData = buffer.int16ChannelData {
            let channelDataValue = int16ChannelData.pointee
            let channelDataValueArray = stride(from: 0, 
                                             to: Int(buffer.frameLength), 
                                             by: buffer.stride).map { channelDataValue[$0] }
            
            let data = Data(bytes: channelDataValueArray, count: channelDataValueArray.count * MemoryLayout<Int16>.size)
            
            chunkCount += 1
            if chunkCount % 100 == 0 {
                print("📊 Audio chunk \(chunkCount): \(data.count) bytes, \(buffer.frameLength) frames")
            }
            
            return data
        }
        
        else {
            print("⚠️ Unsupported audio format: \(buffer.format)")
            return nil
        }
    }
}

// MARK: - Error Handling Extension
extension AudioManager {
    
    func handleAudioError(_ error: Error) {
        print("❌ Audio error occurred: \(error)")
        
        if isRecording {
            stopRecording()
        }
        
        // Post notification for UI to handle
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .audioStreamError, object: error)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let audioStreamError = Notification.Name("AudioStreamError")
}