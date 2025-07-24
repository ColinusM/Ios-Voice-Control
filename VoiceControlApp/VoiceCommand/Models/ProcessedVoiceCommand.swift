import Foundation

/// Represents a processed voice command with associated RCP output
struct ProcessedVoiceCommand: Identifiable, Codable, Equatable {
    /// Unique identifier for SwiftUI lists
    let id = UUID()
    
    /// Original voice input text that was processed
    let originalText: String
    
    /// Generated RCP command from the voice input
    let rcpCommand: RCPCommand
    
    /// Overall confidence in the voice command processing
    var confidence: Double
    
    /// Timestamp when the command was processed
    let timestamp: Date
    
    /// Category of the command (derived from RCP command)
    var category: CommandCategory {
        return rcpCommand.category
    }
    
    /// Processing metadata for debugging and optimization
    let processingMetadata: ProcessingMetadata
    
    init(
        originalText: String,
        rcpCommand: RCPCommand,
        confidence: Double = 1.0,
        processingMetadata: ProcessingMetadata = ProcessingMetadata()
    ) {
        self.originalText = originalText
        self.rcpCommand = rcpCommand
        self.confidence = max(0.0, min(1.0, confidence)) // Clamp between 0.0 and 1.0
        self.timestamp = Date()
        self.processingMetadata = processingMetadata
    }
}

/// Metadata about the command processing for debugging and optimization
struct ProcessingMetadata: Codable, Equatable {
    /// Time taken to process the command (in milliseconds)
    let processingTimeMs: Double
    
    /// Which processor module handled the command
    let processorUsed: String
    
    /// Whether the command required context from previous commands
    let usedContext: Bool
    
    /// Whether the command was part of a compound command
    let isCompoundCommand: Bool
    
    /// Any warnings or notes about the processing
    let processingNotes: [String]
    
    init(
        processingTimeMs: Double = 0.0,
        processorUsed: String = "basic",
        usedContext: Bool = false,
        isCompoundCommand: Bool = false,
        processingNotes: [String] = []
    ) {
        self.processingTimeMs = processingTimeMs
        self.processorUsed = processorUsed
        self.usedContext = usedContext
        self.isCompoundCommand = isCompoundCommand
        self.processingNotes = processingNotes
    }
}

/// Extensions for ProcessedVoiceCommand to support UI and business logic
extension ProcessedVoiceCommand {
    /// Returns age of the command in seconds
    var ageInSeconds: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    /// Returns whether the command should be considered expired
    var isExpired: Bool {
        return ageInSeconds > 30.0 // 30 second expiration as per PRP requirements
    }
    
    /// Returns confidence color for UI display
    var confidenceColor: String {
        if confidence >= 0.8 { return "green" }
        else if confidence >= 0.6 { return "orange" }
        else { return "red" }
    }
    
    /// Returns formatted confidence percentage for display
    var confidencePercentage: String {
        return "\(Int(confidence * 100))%"
    }
    
    /// Returns short description suitable for compact display
    var shortDescription: String {
        if rcpCommand.description.count > 50 {
            return String(rcpCommand.description.prefix(47)) + "..."
        }
        return rcpCommand.description
    }
}

/// Collection extensions for managing lists of processed commands
extension Array where Element == ProcessedVoiceCommand {
    /// Removes expired commands from the array
    mutating func removeExpired() {
        self.removeAll { $0.isExpired }
    }
    
    /// Removes duplicates based on RCP command content
    mutating func removeDuplicates() {
        var seen = Set<String>()
        self = self.filter { command in
            let key = command.rcpCommand.command
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
    
    /// Limits array to maximum number of commands (keeps most recent)
    mutating func limitTo(_ maxCount: Int) {
        if self.count > maxCount {
            self = Array(self.suffix(maxCount))
        }
    }
    
    /// Returns commands sorted by timestamp (most recent first)
    var sortedByTimestamp: [ProcessedVoiceCommand] {
        return self.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Returns commands filtered by minimum confidence threshold
    func withMinimumConfidence(_ threshold: Double) -> [ProcessedVoiceCommand] {
        return self.filter { $0.confidence >= threshold }
    }
    
    /// Returns commands filtered by category
    func filtered(by category: CommandCategory) -> [ProcessedVoiceCommand] {
        return self.filter { $0.category == category }
    }
}