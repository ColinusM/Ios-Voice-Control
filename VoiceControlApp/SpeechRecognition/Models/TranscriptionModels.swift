import Foundation

// MARK: - AssemblyAI WebSocket Message Types

// MARK: - Outbound Messages (Client to Server)
struct SessionBeginMessage: Codable {
    let sample_rate: Int
    let format_turns: Bool?
    let end_of_turn_confidence_threshold: Double?
    let min_end_of_turn_silence_when_confident: Int?
    let max_turn_silence: Int?
    let language: String?
    
    init(config: StreamingConfig) {
        self.sample_rate = config.sampleRate
        self.format_turns = config.formatTurns
        self.end_of_turn_confidence_threshold = config.endOfTurnConfidenceThreshold
        self.min_end_of_turn_silence_when_confident = config.minEndOfTurnSilenceWhenConfident
        self.max_turn_silence = config.maxTurnSilence
        self.language = config.language
    }
}

struct SessionTerminationMessage: Codable {
    let terminate_session: Bool = true
}

// MARK: - Inbound Messages (Server to Client)
struct SessionBeginsResponse: Codable {
    let type: String
    let id: String
    let expires_at: Int
    
    var session_id: String { return id }
}

struct TurnResponse: Codable {
    let type: String
    let turn_order: Int?
    let transcript: String
    let words: [TranscriptWord]?
    let end_of_turn: Bool?
    let turn_is_formatted: Bool?
    let confidence: Double?
    let end_of_turn_confidence: Double?
}

struct SessionTerminatesResponse: Codable {
    let message_type: String
    let audio_duration_seconds: Double?
}

struct ErrorResponse: Codable {
    let message_type: String
    let error: String
    let code: Int?
}

// MARK: - Supporting Models
struct TranscriptWord: Codable {
    let text: String
    let start: Int
    let end: Int
    let confidence: Double
}

// MARK: - Unified Response Model
enum AssemblyAIResponse {
    case sessionBegins(SessionBeginsResponse)
    case turn(TurnResponse)
    case sessionTerminates(SessionTerminatesResponse)
    case error(ErrorResponse)
    
    init?(from data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // AssemblyAI uses both "message_type" and "type" depending on the message
        let messageType = json["message_type"] as? String ?? json["type"] as? String
        
        guard let messageType = messageType else {
            return nil
        }
        
        switch messageType {
        case "SessionBegins", "Begin":
            guard let response = try? JSONDecoder().decode(SessionBeginsResponse.self, from: data) else { return nil }
            self = .sessionBegins(response)
            
        case "PartialTranscript", "FinalTranscript", "Turn":
            guard let response = try? JSONDecoder().decode(TurnResponse.self, from: data) else { return nil }
            self = .turn(response)
            
        case "SessionTerminates":
            guard let response = try? JSONDecoder().decode(SessionTerminatesResponse.self, from: data) else { return nil }
            self = .sessionTerminates(response)
            
        case "Error":
            guard let response = try? JSONDecoder().decode(ErrorResponse.self, from: data) else { return nil }
            self = .error(response)
            
        default:
            return nil
        }
    }
}

// MARK: - Connection State
enum StreamingState: Equatable {
    case disconnected
    case connecting
    case connected
    case streaming
    case gracefulShutdown
    case error(String)
}

// MARK: - Audio Stream Error
enum AudioStreamError: LocalizedError {
    case permissionDenied
    case audioEngineFailure(String)
    case webSocketConnectionFailed(String)
    case audioFormatNotSupported
    case microphoneUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied. Please enable microphone access in Settings."
        case .audioEngineFailure(let message):
            return "Audio engine error: \(message)"
        case .webSocketConnectionFailed(let message):
            return "Connection failed: \(message)"
        case .audioFormatNotSupported:
            return "Audio format not supported"
        case .microphoneUnavailable:
            return "Microphone is unavailable"
        }
    }
}