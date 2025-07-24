import Foundation

/// Processor for compound voice commands containing multiple actions connected by conjunctions
/// Handles commands like "set kick to -6 dB and send to reverb" or "mute guitar then pan it left"
class CompoundCommandProcessor {
    
    // MARK: - Supporting Processors
    
    /// Basic channel processor for core operations
    private let channelProcessor = ChannelProcessor()
    
    /// Routing processor for pan and send operations
    private let routingProcessor = RoutingProcessor()
    
    /// Effects processor for reverb, delay, and compression
    private let effectsProcessor = EffectsProcessor()
    
    // MARK: - Configuration
    
    /// Conjunctions that indicate compound commands
    private let conjunctions = ["and", "then", "also", "plus", "and then", "followed by"]
    
    /// Maximum number of actions allowed in a compound command
    private let maxActions = 4
    
    /// Minimum confidence threshold for compound commands
    private let minimumConfidence = 0.6
    
    // MARK: - Public Interface
    
    /// Process a text input for compound commands
    /// - Parameter text: The voice input text to analyze
    /// - Returns: Array of RCP commands if compound command detected, nil otherwise
    func processCompoundCommand(_ text: String) -> [RCPCommand]? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if text contains conjunctions
        guard containsConjunctions(lowercased) else { return nil }
        
        // Split the command into individual actions
        let actions = splitIntoActions(lowercased)
        
        // Validate action count
        guard actions.count >= 2 && actions.count <= maxActions else { return nil }
        
        // Process each action
        var commands: [RCPCommand] = []
        var contextInstrument: String?
        var contextChannel: Int?
        
        for (index, action) in actions.enumerated() {
            let actionText = action.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty actions
            guard !actionText.isEmpty else { continue }
            
            // Process the action with context from previous actions
            if let command = processIndividualAction(
                actionText,
                contextInstrument: contextInstrument,
                contextChannel: contextChannel,
                actionIndex: index
            ) {
                commands.append(command)
                
                // Update context for subsequent actions
                if let extractedInfo = extractInstrumentAndChannel(from: actionText) {
                    contextInstrument = extractedInfo.instrument
                    contextChannel = extractedInfo.channel
                }
            }
        }
        
        // Return commands only if we successfully processed multiple actions
        return commands.count >= 2 ? commands : nil
    }
    
    /// Check if a command is likely to be a compound command
    /// - Parameter text: The text to analyze
    /// - Returns: True if compound command indicators are detected
    func isCompoundCommand(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // Check for conjunctions
        if containsConjunctions(lowercased) {
            return true
        }
        
        // Check for multiple action indicators
        let actionPatterns = [
            "set.*to.*send", "mute.*pan", "solo.*add", 
            "fader.*reverb", "level.*delay", "gain.*compress"
        ]
        
        for pattern in actionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) != nil {
                return true
            }
        }
        
        return false
    }
    
    /// Get compound command confidence based on structure and content
    /// - Parameter text: The text to analyze
    /// - Returns: Confidence score between 0.0 and 1.0
    func getCompoundCommandConfidence(_ text: String) -> Double {
        let lowercased = text.lowercased()
        var confidence: Double = 0.0
        
        // Base confidence for containing conjunctions
        if containsConjunctions(lowercased) {
            confidence += 0.4
        }
        
        // Bonus for clear action structure
        let actions = splitIntoActions(lowercased)
        if actions.count >= 2 {
            confidence += 0.3
            
            // Bonus for each recognizable action
            for action in actions {
                if isRecognizableAction(action) {
                    confidence += 0.1
                }
            }
        }
        
        // Bonus for instrument context consistency
        if hasConsistentInstrumentContext(actions) {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Private Implementation
    
    /// Check if text contains conjunction words
    private func containsConjunctions(_ text: String) -> Bool {
        for conjunction in conjunctions {
            if text.contains(" \(conjunction) ") {
                return true
            }
        }
        return false
    }
    
    /// Split compound command into individual actions
    private func splitIntoActions(_ text: String) -> [String] {
        var actions: [String] = []
        let currentText = text
        
        // Find the first conjunction and split
        for conjunction in conjunctions.sorted(by: { $0.count > $1.count }) { // Try longer conjunctions first
            if let range = currentText.range(of: " \(conjunction) ") {
                let firstAction = String(currentText[..<range.lowerBound])
                let remainingText = String(currentText[range.upperBound...])
                
                actions.append(firstAction)
                
                // Recursively split the remaining text
                let remainingActions = splitIntoActions(remainingText)
                actions.append(contentsOf: remainingActions)
                
                return actions
            }
        }
        
        // No more conjunctions found, return the remaining text as a single action
        actions.append(currentText)
        return actions
    }
    
    /// Process an individual action within a compound command
    private func processIndividualAction(
        _ actionText: String,
        contextInstrument: String?,
        contextChannel: Int?,
        actionIndex: Int
    ) -> RCPCommand? {
        let enhancedText = enhanceActionWithContext(
            actionText,
            contextInstrument: contextInstrument,
            contextChannel: contextChannel
        )
        
        // Try different processors in order of likelihood
        
        // 1. Channel operations (fader, mute, solo)
        if let command = channelProcessor.processInstrumentFaderCommand(enhancedText) {
            return command
        }
        
        if let command = channelProcessor.processInstrumentMuteCommand(enhancedText) {
            return command
        }
        
        if let command = channelProcessor.processInstrumentSoloCommand(enhancedText) {
            return command
        }
        
        // 2. Routing operations (send, pan)
        if let command = routingProcessor.processSendCommand(enhancedText) {
            return command
        }
        
        if let command = routingProcessor.processPanCommand(enhancedText) {
            return command
        }
        
        if let command = routingProcessor.processStereoCommand(enhancedText) {
            return command
        }
        
        // 3. Effects operations (reverb, delay, compression, EQ)
        if let command = effectsProcessor.processReverbCommand(enhancedText) {
            return command
        }
        
        if let command = effectsProcessor.processDelayCommand(enhancedText) {
            return command
        }
        
        if let command = effectsProcessor.processCompressionCommand(enhancedText) {
            return command
        }
        
        if let command = effectsProcessor.processEQCommand(enhancedText) {
            return command
        }
        
        // 4. Try basic channel operations with context
        if let contextChannel = contextChannel {
            if let command = processBasicChannelOperation(actionText, channel: contextChannel) {
                return command
            }
        }
        
        return nil
    }
    
    /// Enhance an action with context from previous actions
    private func enhanceActionWithContext(
        _ actionText: String,
        contextInstrument: String?,
        contextChannel: Int?
    ) -> String {
        var enhancedText = actionText
        
        // Add instrument context if missing
        if let instrument = contextInstrument,
           !actionText.contains(instrument) &&
           !containsInstrumentReference(actionText) {
            
            // Add instrument context for actions that reference "it"
            if actionText.contains(" it ") || actionText.starts(with: "it ") {
                enhancedText = actionText.replacingOccurrences(of: " it ", with: " \(instrument) ")
                if enhancedText.starts(with: "it ") {
                    enhancedText = "\(instrument) " + String(enhancedText.dropFirst(3))
                }
            }
            // Add instrument for actions without explicit targets
            else if !containsChannelReference(actionText) {
                enhancedText = "\(instrument) \(actionText)"
            }
        }
        
        return enhancedText
    }
    
    /// Extract instrument and channel information from action text
    private func extractInstrumentAndChannel(from text: String) -> (instrument: String, channel: Int?)? {
        let instruments = ["kick", "snare", "hihat", "bass", "guitar", "piano", "vocal", "drums"]
        
        for instrument in instruments {
            if text.contains(instrument) {
                let channel = channelProcessor.getChannelForInstrument(instrument)
                return (instrument: instrument, channel: channel)
            }
        }
        
        // Check for channel numbers
        let channelPattern = #"channel\s+(\d+)"#
        if let regex = try? NSRegularExpression(pattern: channelPattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            
            let channelRange = Range(match.range(at: 1), in: text)
            if let channelRange = channelRange,
               let channel = Int(String(text[channelRange])) {
                return (instrument: "channel \(channel)", channel: channel)
            }
        }
        
        return nil
    }
    
    /// Check if text contains an instrument reference
    private func containsInstrumentReference(_ text: String) -> Bool {
        let instruments = ["kick", "snare", "hihat", "bass", "guitar", "piano", "vocal", "drums"]
        return instruments.contains { text.contains($0) }
    }
    
    /// Check if text contains a channel reference
    private func containsChannelReference(_ text: String) -> Bool {
        return text.contains("channel") || text.range(of: #"\d+"#, options: .regularExpression) != nil
    }
    
    /// Process basic channel operations with explicit channel number
    private func processBasicChannelOperation(_ text: String, channel: Int) -> RCPCommand? {
        let lowercased = text.lowercased()
        
        // Look for level/fader operations
        if let levelMatch = extractLevelValue(from: lowercased) {
            let clampedLevel = max(-60.0, min(10.0, levelMatch))
            let rcpLevel = Int(clampedLevel * 100)
            
            return RCPCommand(
                command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                description: "Set channel \(channel) to \(clampedLevel) dB",
                category: .channelFader
            )
        }
        
        // Look for mute operations
        if lowercased.contains("mute") {
            let muteValue = lowercased.contains("unmute") ? 0 : 1
            let description = muteValue == 1 ? "Mute channel \(channel)" : "Unmute channel \(channel)"
            
            return RCPCommand(
                command: "set MIXER:Current/Channel/Mute \(channel-1) 0 \(muteValue)",
                description: description,
                category: .channelMute
            )
        }
        
        // Look for solo operations
        if lowercased.contains("solo") {
            let soloValue = lowercased.contains("unsolo") ? 0 : 1
            let description = soloValue == 1 ? "Solo channel \(channel)" : "Unsolo channel \(channel)"
            
            return RCPCommand(
                command: "set MIXER:Current/Channel/Solo \(channel-1) 0 \(soloValue)",
                description: description,
                category: .channelSolo
            )
        }
        
        return nil
    }
    
    /// Extract a level value from text
    private func extractLevelValue(from text: String) -> Double? {
        let patterns = [
            #"([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)"#,
            #"to\s+([+-]?\d+(?:\.\d+)?)"#,
            #"([+-]?\d+(?:\.\d+)?)\s+db"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let valueRange = Range(match.range(at: 1), in: text)
                if let valueRange = valueRange,
                   let value = Double(String(text[valueRange])) {
                    return value
                }
            }
        }
        
        return nil
    }
    
    /// Check if an action is recognizable by any processor
    private func isRecognizableAction(_ action: String) -> Bool {
        let testText = action.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Test with each processor
        if channelProcessor.processInstrumentFaderCommand(testText) != nil ||
           channelProcessor.processInstrumentMuteCommand(testText) != nil ||
           channelProcessor.processInstrumentSoloCommand(testText) != nil {
            return true
        }
        
        if routingProcessor.processSendCommand(testText) != nil ||
           routingProcessor.processPanCommand(testText) != nil ||
           routingProcessor.processStereoCommand(testText) != nil {
            return true
        }
        
        if effectsProcessor.processReverbCommand(testText) != nil ||
           effectsProcessor.processDelayCommand(testText) != nil ||
           effectsProcessor.processCompressionCommand(testText) != nil ||
           effectsProcessor.processEQCommand(testText) != nil {
            return true
        }
        
        return false
    }
    
    /// Check if actions have consistent instrument context
    private func hasConsistentInstrumentContext(_ actions: [String]) -> Bool {
        guard actions.count >= 2 else { return false }
        
        var contextInstrument: String?
        
        for action in actions {
            if let extracted = extractInstrumentAndChannel(from: action) {
                if let existing = contextInstrument {
                    if existing != extracted.instrument && 
                       !action.contains(" it ") && 
                       !action.starts(with: "it ") {
                        return false // Inconsistent instruments
                    }
                } else {
                    contextInstrument = extracted.instrument
                }
            }
        }
        
        return contextInstrument != nil
    }
}

// MARK: - Supporting Extensions

// Note: getChannelForInstrument method already exists in ChannelProcessor

// MARK: - Compound Command Models

/// Represents a compound command with multiple actions
struct CompoundCommand {
    let originalText: String
    let actions: [String]
    let commands: [RCPCommand]
    let confidence: Double
    let processingTimeMs: Double
}

/// Result of compound command processing
struct CompoundProcessingResult {
    let isCompound: Bool
    let commands: [RCPCommand]
    let confidence: Double
    let actionCount: Int
    let processingNotes: [String]
}