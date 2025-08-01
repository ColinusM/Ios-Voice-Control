import Foundation

/// Represents a Yamaha RCP protocol command generated from voice input
struct RCPCommand: Codable, Equatable {
    /// The actual Yamaha RCP protocol command string
    let command: String
    
    /// Human-readable description of the command
    let description: String
    
    /// Confidence score for the command recognition (0.0 to 1.0)
    var confidence: Double
    
    /// Category of the command for organization and filtering
    let category: CommandCategory
    
    /// Timestamp when the command was generated
    let timestamp: Date
    
    init(command: String, description: String, confidence: Double = 1.0, category: CommandCategory = .unknown) {
        self.command = command
        self.description = description
        self.confidence = max(0.0, min(1.0, confidence)) // Clamp between 0.0 and 1.0
        self.category = category
        self.timestamp = Date()
    }
}

/// Categories of voice commands for professional audio mixing
enum CommandCategory: String, Codable, CaseIterable {
    case channelFader = "channel_fader"
    case channelMute = "channel_mute"
    case channelSolo = "channel_solo"
    case routing = "routing"
    case effects = "effects"
    case scene = "scene"
    case dca = "dca"
    case eq = "eq"
    case dynamics = "dynamics"
    case labeling = "labeling"
    case unknown = "unknown"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .channelFader:
            return "Channel Fader"
        case .channelMute:
            return "Channel Mute"
        case .channelSolo:
            return "Channel Solo"
        case .routing:
            return "Routing"
        case .effects:
            return "Effects"
        case .scene:
            return "Scene"
        case .dca:
            return "DCA"
        case .eq:
            return "EQ"
        case .dynamics:
            return "Dynamics"
        case .labeling:
            return "Labeling"
        case .unknown:
            return "Unknown"
        }
    }
    
    /// Color associated with command category for UI
    var color: String {
        switch self {
        case .channelFader:
            return "blue"
        case .channelMute, .channelSolo:
            return "red"
        case .routing:
            return "purple"
        case .effects:
            return "green"
        case .scene:
            return "orange"
        case .dca:
            return "yellow"
        case .eq, .dynamics:
            return "cyan"
        case .labeling:
            return "gray"
        case .unknown:
            return "secondary"
        }
    }
}

