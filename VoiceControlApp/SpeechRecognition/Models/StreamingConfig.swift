import Foundation
import AVFoundation

// MARK: - AssemblyAI Streaming Configuration
struct StreamingConfig {
    // API Configuration
    let apiKey: String = "a1acc40bebd044b888d821c9de6c3d69"
    let websocketEndpoint: String = "wss://streaming.assemblyai.com/v3/ws"
    
    // Audio Configuration
    let sampleRate: Int = 16000
    let encoding: String = "pcm_s16le"
    let channels: Int = 1
    
    // Streaming Parameters
    let chunkDuration: TimeInterval = 0.05 // 50ms chunks (optimal for real-time)
    let bufferSize: UInt32 = 1024
    
    // Connection Configuration
    let connectionTimeout: TimeInterval = 10.0
    let maxReconnectAttempts: Int = 3
    
    // Transcription Settings
    let language: String = "en"
    let formatTurns: Bool = false
    let endOfTurnConfidenceThreshold: Double = 0.7
    let minEndOfTurnSilenceWhenConfident: Int = 160 // milliseconds
    let maxTurnSilence: Int = 2400 // milliseconds
    
    static let shared = StreamingConfig()
    
    private init() {}
}

// MARK: - Audio Format Helper
extension StreamingConfig {
    var audioFormatSettings: [String: Any] {
        return [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}