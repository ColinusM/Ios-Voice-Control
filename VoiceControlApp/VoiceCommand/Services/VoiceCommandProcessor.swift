import Foundation
import Combine

/// Main service class for processing voice input into RCP commands
/// Follows ObservableObject pattern for SwiftUI integration
class VoiceCommandProcessor: ObservableObject {
    // MARK: - Published Properties
    
    /// List of recently processed commands for UI display
    @Published internal var recentCommands: [ProcessedVoiceCommand] = []
    
    /// Current processing state
    @Published internal var isProcessing: Bool = false
    
    /// Error message for UI display
    @Published internal var errorMessage: String?
    
    // MARK: - Configuration Properties
    
    /// Maximum number of commands to keep in memory
    private let maxCommands = 10
    
    /// Minimum confidence threshold for displaying commands
    private let confidenceThreshold = 0.5
    
    /// Debounce interval for processing (in seconds)
    private let debounceInterval: TimeInterval = 1.0
    
    // MARK: - Processing Infrastructure
    
    /// Timer for periodic cleanup of expired commands
    private var cleanupTimer: Timer?
    
    /// Last processing timestamp for debouncing
    private var lastProcessingTime: Date = Date()
    
    /// Professional audio terms database (will be initialized later)
    private var audioTerms: ProfessionalAudioTerms?
    
    /// Advanced channel processor for instrument-based commands
    private let channelProcessor = ChannelProcessor()
    
    /// Advanced routing processor for send-to-mix and pan commands
    private let routingProcessor = RoutingProcessor()
    
    /// Advanced effects processor for reverb, delay, and compression commands
    private let effectsProcessor = EffectsProcessor()
    
    /// Context manager for intelligent processing and learning
    private let contextManager = ContextManager()
    
    /// Compound command processor for multi-action commands
    private let compoundProcessor = CompoundCommandProcessor()
    

    
    /// Processing queue for background work
    private let processingQueue = DispatchQueue(label: "voice.command.processing", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init() {
        setupCleanupTimer()
        loadAudioTermsDatabase()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Main entry point for processing voice transcription text
    /// - Parameter text: The transcribed text from speech recognition
    func processTranscription(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard text.count <= ValidationLimits.maxInputLength else {
            Task { @MainActor in
                self.setError("Input text too long (max \(ValidationLimits.maxInputLength) characters)")
            }
            return
        }
        
        // Clear any previous error
        Task { @MainActor in
            self.errorMessage = nil
        }
        
        // Debounce processing to avoid overwhelming the system
        let now = Date()
        lastProcessingTime = now
        
        // Process asynchronously without blocking UI
        Task.detached { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * 0.5)) // 500ms delay
            
            // Check if this is still the latest request
            guard let self = self, await self.lastProcessingTime == now else { return }
            
            await self.performVoiceCommandProcessing(text)
        }
    }
    
    /// Clears all recent commands
    @MainActor func clearCommands() {
        recentCommands.removeAll()
    }
    
    /// Forces cleanup of expired commands
    @MainActor func cleanupExpiredCommands() {
        var updated = recentCommands
        updated.removeExpired()
        if updated.count != recentCommands.count {
            recentCommands = updated
        }
    }
    
    /// Add a custom instrument label for context-aware processing
    /// - Parameters:
    ///   - label: User's preferred term (e.g., "the red one")
    ///   - channel: Channel number to map to
    ///   - instrument: Standard instrument name
    func addCustomInstrumentLabel(_ label: String, channel: Int, instrument: String) {
        contextManager.addInstrumentLabel(label, channel: channel, instrument: instrument)
    }
    
    /// Get suggestions for improving command recognition
    /// - Parameter text: The input text to analyze
    /// - Returns: Array of context suggestions
    func getContextSuggestions(for text: String) -> [ContextSuggestion] {
        return contextManager.getSuggestionsForImprovement(text)
    }
    
    /// Reset context and learned patterns
    func resetContext() {
        contextManager.resetContext()
    }
    
    /// Get current context confidence level
    var contextConfidence: Double {
        return contextManager.contextConfidence
    }
    
    /// Get learning prompt manager for UI integration

    }
    
    /// Performs the actual voice command processing
    private func performVoiceCommandProcessing(_ text: String) async {
        let startTime = Date()
        
        await MainActor.run {
            self.isProcessing = true
        }
        
        do {
            // Extract voice commands from text
            let commands = await extractVoiceCommands(from: text)
            
            // Calculate processing time
            let processingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            
            // Update commands with processing metadata
            let processedCommands = commands.map { command in
                return ProcessedVoiceCommand(
                    originalText: command.originalText,
                    rcpCommand: command.rcpCommand,
                    confidence: command.confidence,
                    processingMetadata: ProcessingMetadata(
                        processingTimeMs: processingTime,
                        processorUsed: "basic",
                        usedContext: false,
                        isCompoundCommand: text.contains(" and ") || text.contains(" then "),
                        processingNotes: []
                    )
                )
            }
            
            await MainActor.run {
                self.updateCommands(processedCommands)
                self.isProcessing = false
                
                // Learn from successful commands for context improvement
                for command in processedCommands {
                    self.contextManager.learnFromCommand(command)
                    

                }
            }
            
        } catch {
            await MainActor.run {
                self.setError("Processing error: \(error.localizedDescription)")
                self.isProcessing = false
            }
        }
    }
    
    /// Extracts voice commands from input text using pattern matching with context awareness
    private func extractVoiceCommands(from text: String) async -> [ProcessedVoiceCommand] {
        // Text should already be preprocessed by SpeechRecognitionManager
        let lowercased = text.lowercased()
        var commands: [ProcessedVoiceCommand] = []
        
        // Phase 0: Context-aware preprocessing (use original text for context)
        let contextResult = contextManager.processWithContext(text)
        
        // Check for custom instrument labels first
        let customChannel = contextManager.getChannelForCustomLabel(text)
        if let channel = customChannel {
            print("🎯 Context: Found custom instrument label mapping to channel \(channel)")
        }
        
        // Phase 0.5: Compound command detection and processing
        if compoundProcessor.isCompoundCommand(text) {
            print("🔗 Compound: Detected compound command")
            
            if let compoundCommands = compoundProcessor.processCompoundCommand(text) {
                let compoundConfidence = compoundProcessor.getCompoundCommandConfidence(text)
                
                // Convert RCPCommands to ProcessedVoiceCommands
                let processedCompounds = compoundCommands.enumerated().map { (index, rcpCommand) in
                    return ProcessedVoiceCommand(
                        originalText: text,
                        rcpCommand: rcpCommand,
                        confidence: compoundConfidence,
                        processingMetadata: ProcessingMetadata(
                            processingTimeMs: 4.5,
                            processorUsed: "compound_processor",
                            usedContext: true,
                            isCompoundCommand: true,
                            processingNotes: ["Multi-action command processing", "Action \(index + 1) of \(compoundCommands.count)"]
                        )
                    )
                }
                
                print("🔗 Compound: Successfully processed \(compoundCommands.count) actions")
                return processedCompounds
            }
        }
        
        // Phase 1: Basic channel/number-based commands
        
        // Basic channel fader commands (numeric channels)
        if let command = await processChannelFaderCommand(lowercased) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.8
            ))
        }
        
        // Basic mute commands (numeric channels)
        if let command = await processMuteCommand(lowercased) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.8
            ))
        }
        
        // Scene recall commands
        if let command = await processSceneCommand(lowercased) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.9
            ))
        }
        
        // Phase 2: Advanced instrument-based commands
        
        // Instrument fader commands
        if let command = channelProcessor.processInstrumentFaderCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.7,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.5,
                    processorUsed: "channel_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used instrument-to-channel mapping"]
                )
            ))
        }
        
        // Instrument mute commands
        if let command = channelProcessor.processInstrumentMuteCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.7,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.0,
                    processorUsed: "channel_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used instrument-to-channel mapping"]
                )
            ))
        }
        
        // Instrument solo commands
        if let command = channelProcessor.processInstrumentSoloCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.7,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.0,
                    processorUsed: "channel_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used instrument-to-channel mapping"]
                )
            ))
        }
        
        // Instrument pan commands (basic from ChannelProcessor)
        if let command = channelProcessor.processInstrumentPanCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.7,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 1.8,
                    processorUsed: "channel_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used instrument-to-channel mapping"]
                )
            ))
        }
        
        // Advanced routing commands (send-to-mix, aux sends)
        if let command = routingProcessor.processSendCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.75,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 3.2,
                    processorUsed: "routing_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used aux send mapping", "Applied send level limits"]
                )
            ))
        }
        
        // Advanced pan commands with fine control
        if let command = routingProcessor.processPanCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.8,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.1,
                    processorUsed: "routing_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used advanced pan positioning"]
                )
            ))
        }
        
        // Routing matrix commands
        if let command = routingProcessor.processRoutingCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.75,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.8,
                    processorUsed: "routing_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Used routing matrix configuration"]
                )
            ))
        }
        
        // Stereo width/imaging commands
        if let command = routingProcessor.processStereoCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.7,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.4,
                    processorUsed: "routing_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Applied stereo width processing"]
                )
            ))
        }
        
        // Phase 2: Advanced effects commands
        
        // Reverb commands
        if let command = effectsProcessor.processReverbCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.75,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 3.5,
                    processorUsed: "effects_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Applied reverb processing", "Used reverb type mapping"]
                )
            ))
        }
        
        // Delay commands
        if let command = effectsProcessor.processDelayCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.75,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 3.2,
                    processorUsed: "effects_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Applied delay processing", "Used timing-based delay mapping"]
                )
            ))
        }
        
        // Compression commands
        if let command = effectsProcessor.processCompressionCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.8,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.8,
                    processorUsed: "effects_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Applied compression processing", "Used professional compression settings"]
                )
            ))
        }
        
        // EQ commands
        if let command = effectsProcessor.processEQCommand(text) {
            commands.append(ProcessedVoiceCommand(
                originalText: text,
                rcpCommand: command,
                confidence: 0.8,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 2.6,
                    processorUsed: "effects_processor",
                    usedContext: true,
                    isCompoundCommand: false,
                    processingNotes: ["Applied EQ processing", "Used frequency-based EQ mapping"]
                )
            ))
        }
        
        return commands.filter { $0.confidence >= confidenceThreshold }
    }
    
    /// Basic channel fader command processing
    private func processChannelFaderCommand(_ text: String) async -> RCPCommand? {
        // Pattern: "set channel X to Y dB" or "channel X to Y"
        let patterns = [
            #"(?:set\s+)?channel\s+(\d+)\s+to\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#,
            #"(?:set\s+)?(?:channel\s+)?(\d+)\s+to\s+([+-]?\d+(?:\.\d+)?)\s*(?:db|dB)?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let channelRange = Range(match.range(at: 1), in: text)
                let levelRange = Range(match.range(at: 2), in: text)
                
                if let channelRange = channelRange, let levelRange = levelRange,
                   let channel = Int(String(text[channelRange])),
                   let level = Double(String(text[levelRange])) {
                    
                    guard ValidationLimits.isValidChannel(channel) else { continue }
                    
                    let clampedLevel = ValidationLimits.clampDB(level)
                    let rcpLevel = Int(clampedLevel * 100) // Convert to RCP format
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Channel/Fader/Level \(channel-1) 0 \(rcpLevel)",
                        description: "Set channel \(channel) to \(clampedLevel) dB",
                        category: .channelFader
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Basic mute command processing
    private func processMuteCommand(_ text: String) async -> RCPCommand? {
        // Pattern: "mute channel X" or "unmute channel X"
        let patterns = [
            #"(mute|unmute)\s+channel\s+(\d+)"#,
            #"channel\s+(\d+)\s+(mute|unmute)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                var muteAction: String
                var channel: Int
                
                if pattern.starts(with: "(mute|unmute)") {
                    // First pattern: action comes first
                    let actionRange = Range(match.range(at: 1), in: text)
                    let channelRange = Range(match.range(at: 2), in: text)
                    
                    guard let actionRange = actionRange, let channelRange = channelRange else { continue }
                    
                    muteAction = String(text[actionRange])
                    guard let channelNum = Int(String(text[channelRange])) else { continue }
                    channel = channelNum
                } else {
                    // Second pattern: channel comes first
                    let channelRange = Range(match.range(at: 1), in: text)
                    let actionRange = Range(match.range(at: 2), in: text)
                    
                    guard let channelRange = channelRange, let actionRange = actionRange else { continue }
                    
                    guard let channelNum = Int(String(text[channelRange])) else { continue }
                    channel = channelNum
                    muteAction = String(text[actionRange])
                }
                
                guard ValidationLimits.isValidChannel(channel) else { continue }
                
                let muteValue = muteAction == "mute" ? 1 : 0
                let description = muteAction == "mute" ? "Mute channel \(channel)" : "Unmute channel \(channel)"
                
                return RCPCommand(
                    command: "set MIXER:Current/Channel/Mute \(channel-1) 0 \(muteValue)",
                    description: description,
                    category: .channelMute
                )
            }
        }
        
        return nil
    }
    
    /// Basic scene recall command processing
    private func processSceneCommand(_ text: String) async -> RCPCommand? {
        // Pattern: "recall scene X" or "load scene X" or "scene X"
        let patterns = [
            #"(?:recall|load)\s+scene\s+(\d+)"#,
            #"scene\s+(\d+)(?:\s+(?:recall|load))?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let sceneRange = Range(match.range(at: 1), in: text)
                
                if let sceneRange = sceneRange,
                   let scene = Int(String(text[sceneRange])) {
                    
                    guard ValidationLimits.isValidScene(scene) else { continue }
                    
                    return RCPCommand(
                        command: "set MIXER:Current/Scene/Recall \(scene-1)",
                        description: "Recall scene \(scene)",
                        category: .scene
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Updates the command list with new commands
    @MainActor private func updateCommands(_ newCommands: [ProcessedVoiceCommand]) {
        // Add new commands
        recentCommands.append(contentsOf: newCommands)
        
        // Remove duplicates and limit count
        recentCommands.removeDuplicates()
        recentCommands.limitTo(maxCommands)
        
        // Sort by timestamp (most recent first)
        recentCommands = recentCommands.sortedByTimestamp
    }
    
    /// Sets an error message for UI display
    @MainActor private func setError(_ message: String) {
        errorMessage = message
        print("[VoiceCommandProcessor] Error: \(message)")
    }
    
    /// Sets up the cleanup timer for expired commands
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.cleanupExpiredCommands()
            }
        }
    }
    
    /// Loads the professional audio terms database
    private func loadAudioTermsDatabase() {
        // This will be implemented when we create the ProfessionalAudioTerms class
        // For now, using basic pattern matching
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
        
        // Handle compound numbers like "twenty one" -> "21" (more complex patterns)
        processedText = handleCompoundNumbers(processedText)
        
        // Clean up extra spaces
        processedText = processedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Log conversion for debugging
        if processedText != text {
            print("📝 Number conversion: \"\(text)\" → \"\(processedText)\"")
        }
        
        return processedText
    }
    
    /// Handle compound spoken numbers that require more complex processing
    /// - Parameter text: Text that may contain compound numbers
    /// - Returns: Text with compound numbers converted to digits
    private func handleCompoundNumbers(_ text: String) -> String {
        var processedText = text
        
        // Handle "twenty X" patterns that weren't caught above
        let compoundPatterns: [(String, String)] = [
            ("twenty (one|two|three|four|five|six|seven|eight|nine)", "2$1"),
            ("thirty (one|two|three|four|five|six|seven|eight|nine)", "3$1"),
            ("forty (one|two|three|four|five|six|seven|eight|nine)", "4$1"),
            ("fifty (one|two|three|four|five|six|seven|eight|nine)", "5$1"),
            ("sixty (one|two|three|four|five|six|seven|eight|nine)", "6$1"),
        ]
        
        for (pattern, replacement) in compoundPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(
                    in: processedText,
                    options: [],
                    range: range,
                    withTemplate: replacement
                ).replacingOccurrences(of: "2one", with: "21")
                .replacingOccurrences(of: "2two", with: "22")
                .replacingOccurrences(of: "2three", with: "23")
                .replacingOccurrences(of: "2four", with: "24")
                .replacingOccurrences(of: "2five", with: "25")
                .replacingOccurrences(of: "2six", with: "26")
                .replacingOccurrences(of: "2seven", with: "27")
                .replacingOccurrences(of: "2eight", with: "28")
                .replacingOccurrences(of: "2nine", with: "29")
                .replacingOccurrences(of: "3one", with: "31")
                .replacingOccurrences(of: "3two", with: "32")
                // Add more mappings as needed
            }
        }
        
        return processedText
    }
}

// MARK: - Error Types

enum VoiceCommandError: LocalizedError {
    case invalidInput(String)
    case processingFailed(String)
    case databaseNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .processingFailed(let details):
            return "Processing failed: \(details)"
        case .databaseNotLoaded:
            return "Professional audio terms database not loaded"
        }
    }
}