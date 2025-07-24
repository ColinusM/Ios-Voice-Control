import Foundation
import Combine

// Forward declarations to avoid circular dependencies
extension ProcessedVoiceCommand {}

/// Context-aware processing manager for intelligent voice command recognition
/// Learns user patterns, maintains session state, and provides adaptive processing
class ContextManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current session context state
    @Published private(set) var sessionContext: SessionContext
    
    /// User's custom instrument labels and mappings
    @Published private(set) var instrumentLabels: [String: InstrumentLabel] = [:]
    
    /// Recently processed commands for pattern learning
    @Published private(set) var commandHistory: [ProcessedVoiceCommand] = []
    
    /// Context confidence metrics
    @Published private(set) var contextConfidence: Double = 0.5
    
    // MARK: - Configuration Properties
    
    /// Maximum number of commands to keep in history for learning
    private let maxHistoryCount = 50
    
    /// Minimum pattern occurrences before adapting
    private let minPatternThreshold = 3
    
    /// Learning rate for context adaptation
    private let learningRate = 0.1
    
    // MARK: - Processing Infrastructure
    
    /// Background queue for context processing
    private let contextQueue = DispatchQueue(label: "context.processing", qos: .utility)
    
    /// Pattern learning engine
    private let patternLearner = PatternLearningEngine()
    
    /// Session state persistence
    private let sessionStorage = SessionStorage()
    
    // MARK: - Initialization
    
    init() {
        self.sessionContext = SessionContext()
        loadSessionState()
        setupPatternLearning()
    }
    
    // MARK: - Public Interface
    
    /// Process a command with context awareness
    /// - Parameters:
    ///   - text: Raw voice input text
    ///   - timestamp: When the command was spoken
    /// - Returns: Context-enhanced processing suggestions
    func processWithContext(_ text: String, timestamp: Date = Date()) -> ContextProcessingResult {
        let startTime = Date()
        
        // Analyze current context
        let contextAnalysis = analyzeCurrentContext(text)
        
        // Apply learned patterns
        let patternSuggestions = patternLearner.suggestImprovedParsing(text, context: sessionContext)
        
        // Check for instrument label usage
        let instrumentContext = analyzeInstrumentContext(text)
        
        // Generate processing suggestions
        let suggestions = generateProcessingSuggestions(
            text: text,
            contextAnalysis: contextAnalysis,
            patternSuggestions: patternSuggestions,
            instrumentContext: instrumentContext
        )
        
        // Update context confidence
        updateContextConfidence(based: suggestions)
        
        let processingTime = Date().timeIntervalSince(startTime) * 1000
        
        return ContextProcessingResult(
            originalText: text,
            suggestions: suggestions,
            contextConfidence: contextConfidence,
            processingTimeMs: processingTime,
            sessionContext: sessionContext,
            instrumentContext: instrumentContext
        )
    }
    
    /// Learn from a successfully processed command
    /// - Parameter command: The processed command to learn from
    func learnFromCommand(_ command: ProcessedVoiceCommand) {
        contextQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Add to command history
            DispatchQueue.main.async {
                self.commandHistory.append(command)
                if self.commandHistory.count > self.maxHistoryCount {
                    self.commandHistory.removeFirst()
                }
            }
            
            // Extract learning patterns
            self.patternLearner.extractPatternsFrom(command)
            
            // Update instrument context if relevant
            self.updateInstrumentContext(from: command)
            
            // Adapt processing strategies
            self.adaptProcessingStrategies(from: command)
        }
    }
    
    /// Add or update a custom instrument label
    /// - Parameters:
    ///   - label: The user's preferred term
    ///   - channel: The channel number
    ///   - instrument: The standard instrument name
    ///   - confidence: How confident we are in this mapping
    func addInstrumentLabel(_ label: String, channel: Int, instrument: String, confidence: Double = 1.0) {
        let instrumentLabel = InstrumentLabel(
            userLabel: label.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            standardName: instrument,
            channelNumber: channel,
            confidence: confidence,
            usageCount: 1,
            lastUsed: Date()
        )
        
        instrumentLabels[label.lowercased()] = instrumentLabel
        saveSessionState()
        
        print("🎛️ Added instrument label: '\(label)' -> \(instrument) (Channel \(channel))")
    }
    
    /// Get channel for a user's custom instrument label
    /// - Parameter text: The text potentially containing custom labels
    /// - Returns: Channel number if found, nil otherwise
    func getChannelForCustomLabel(_ text: String) -> Int? {
        let lowercasedText = text.lowercased()
        
        // Check for exact matches first
        for (label, instrumentLabel) in instrumentLabels {
            if lowercasedText.contains(label) {
                // Update usage statistics
                var updatedLabel = instrumentLabel
                updatedLabel.usageCount += 1
                updatedLabel.lastUsed = Date()
                instrumentLabels[label] = updatedLabel
                
                return instrumentLabel.channelNumber
            }
        }
        
        // Check for partial matches with higher confidence threshold
        for (label, instrumentLabel) in instrumentLabels {
            if instrumentLabel.confidence > 0.7 && (lowercasedText.contains(label) || label.contains(lowercasedText)) {
                return instrumentLabel.channelNumber
            }
        }
        
        return nil
    }
    
    /// Update session context with new information
    /// - Parameter context: New context information to merge
    func updateSessionContext(_ context: SessionContext) {
        sessionContext = sessionContext.merged(with: context)
        saveSessionState()
    }
    
    /// Clear all learned patterns and custom labels
    func resetContext() {
        sessionContext = SessionContext()
        instrumentLabels.removeAll()
        commandHistory.removeAll()
        contextConfidence = 0.5
        patternLearner.reset()
        saveSessionState()
        
        print("🔄 Context manager reset to default state")
    }
    
    /// Get context-aware suggestions for improving command recognition
    /// - Parameter text: The input text to analyze
    /// - Returns: Array of suggestions for better recognition
    func getSuggestionsForImprovement(_ text: String) -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []
        
        // Analyze for potential instrument labels
        if let instrumentSuggestion = analyzeForInstrumentLabeling(text) {
            suggestions.append(instrumentSuggestion)
        }
        
        // Check for pattern learning opportunities
        let patternSuggestions = patternLearner.suggestPatternImprovements(text, history: commandHistory)
        suggestions.append(contentsOf: patternSuggestions)
        
        // Analyze for context enhancement opportunities
        if contextConfidence < 0.7 {
            let contextSuggestion = ContextSuggestion(
                type: .contextEnhancement,
                description: "Low context confidence. Consider adding more specific instrument labels.",
                confidence: 1.0 - contextConfidence,
                actionable: true
            )
            suggestions.append(contextSuggestion)
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Private Implementation
    
    /// Analyze current context for the given text
    private func analyzeCurrentContext(_ text: String) -> ContextAnalysis {
        let lowercasedText = text.lowercased()
        
        // Determine likely command category
        let category = determineCommandCategory(lowercasedText)
        
        // Analyze instrument references
        let instrumentReferences = extractInstrumentReferences(lowercasedText)
        
        // Check for time-based context (recent similar commands)
        let recentSimilarCommands = findRecentSimilarCommands(lowercasedText)
        
        // Assess complexity
        let complexity = assessCommandComplexity(lowercasedText)
        
        return ContextAnalysis(
            category: category,
            instrumentReferences: instrumentReferences,
            recentSimilarCommands: recentSimilarCommands,
            complexity: complexity,
            timestamp: Date()
        )
    }
    
    /// Analyze instrument context in the text
    private func analyzeInstrumentContext(_ text: String) -> InstrumentContext {
        let lowercasedText = text.lowercased()
        var detectedInstruments: [String] = []
        var customLabelMatches: [String] = []
        var confidence: Double = 0.0
        
        // Check for standard instrument names
        let standardInstruments = ["kick", "snare", "hihat", "bass", "guitar", "piano", "vocal", "drums"]
        for instrument in standardInstruments {
            if lowercasedText.contains(instrument) {
                detectedInstruments.append(instrument)
                confidence += 0.1
            }
        }
        
        // Check for custom labels
        for (label, instrumentLabel) in instrumentLabels {
            if lowercasedText.contains(label) {
                customLabelMatches.append(label)
                detectedInstruments.append(instrumentLabel.standardName)
                confidence += instrumentLabel.confidence * 0.2
            }
        }
        
        return InstrumentContext(
            detectedInstruments: detectedInstruments,
            customLabelMatches: customLabelMatches,
            confidence: min(confidence, 1.0)
        )
    }
    
    /// Generate processing suggestions based on context analysis
    private func generateProcessingSuggestions(
        text: String,
        contextAnalysis: ContextAnalysis,
        patternSuggestions: [PatternSuggestion],
        instrumentContext: InstrumentContext
    ) -> [ProcessingSuggestion] {
        var suggestions: [ProcessingSuggestion] = []
        
        // Add pattern-based suggestions
        for patternSuggestion in patternSuggestions {
            let suggestion = ProcessingSuggestion(
                processorType: patternSuggestion.recommendedProcessor,
                confidence: patternSuggestion.confidence,
                reasoning: patternSuggestion.reasoning,
                metadata: ["pattern_based": true]
            )
            suggestions.append(suggestion)
        }
        
        // Add instrument context suggestions
        if instrumentContext.confidence > 0.5 {
            for instrument in instrumentContext.detectedInstruments {
                let suggestion = ProcessingSuggestion(
                    processorType: determineProcessorForInstrument(instrument),
                    confidence: instrumentContext.confidence,
                    reasoning: "Detected instrument: \(instrument)",
                    metadata: ["instrument_based": true, "instrument": instrument]
                )
                suggestions.append(suggestion)
            }
        }
        
        // Add category-based suggestions
        let categoryProcessor = determineProcessorForCategory(contextAnalysis.category)
        let categorySuggestion = ProcessingSuggestion(
            processorType: categoryProcessor,
            confidence: 0.6,
            reasoning: "Based on command category: \(contextAnalysis.category)",
            metadata: ["category_based": true]
        )
        suggestions.append(categorySuggestion)
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    /// Update context confidence based on processing suggestions
    private func updateContextConfidence(based suggestions: [ProcessingSuggestion]) {
        let avgSuggestionConfidence = suggestions.isEmpty ? 0.5 : 
            suggestions.map { $0.confidence }.reduce(0, +) / Double(suggestions.count)
        
        // Apply learning rate to gradually adjust confidence
        contextConfidence = contextConfidence * (1 - learningRate) + avgSuggestionConfidence * learningRate
        contextConfidence = max(0.1, min(1.0, contextConfidence))
    }
    
    /// Update instrument context from processed command
    private func updateInstrumentContext(from command: ProcessedVoiceCommand) {
        // Extract potential instrument references
        let text = command.originalText.lowercased()
        
        // Look for patterns like "the blue channel" or "my kick drum"
        if let customPattern = extractCustomInstrumentPattern(text) {
            // This would be enhanced with user confirmation in a real implementation
            addInstrumentLabel(
                customPattern.label,
                channel: customPattern.suggestedChannel,
                instrument: customPattern.suggestedInstrument,
                confidence: 0.5
            )
        }
    }
    
    /// Helper method to extract custom instrument patterns
    private func extractCustomInstrumentPattern(_ text: String) -> (label: String, suggestedChannel: Int, suggestedInstrument: String)? {
        // Pattern matching for custom labels like "the red one", "channel A", etc.
        let patterns = [
            #"(?:the\s+)?(\w+)\s+(?:channel|one|track)"#,
            #"(?:my\s+)?(\w+)\s+(kick|snare|guitar|bass|piano|vocal)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                
                let labelRange = Range(match.range(at: 1), in: text)
                guard let labelRange = labelRange else { continue }
                
                let label = String(text[labelRange])
                
                // Try to determine suggested mapping based on context
                if match.numberOfRanges > 2 {
                    let instrumentRange = Range(match.range(at: 2), in: text)
                    if let instrumentRange = instrumentRange {
                        let instrument = String(text[instrumentRange])
                        let suggestedChannel = getStandardChannelForInstrument(instrument)
                        return (label: label, suggestedChannel: suggestedChannel, suggestedInstrument: instrument)
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Get standard channel mapping for an instrument
    private func getStandardChannelForInstrument(_ instrument: String) -> Int {
        let standardMapping: [String: Int] = [
            "kick": 1, "snare": 2, "hihat": 3,
            "bass": 8, "guitar": 9, "piano": 11, "vocal": 12
        ]
        return standardMapping[instrument.lowercased()] ?? 1
    }
    
    /// Additional helper methods for context analysis
    private func determineCommandCategory(_ text: String) -> CommandCategory {
        if text.contains("reverb") || text.contains("delay") || text.contains("compress") {
            return .effects
        } else if text.contains("pan") || text.contains("send") {
            return .routing
        } else if text.contains("mute") {
            return .channelMute
        } else if text.contains("solo") {
            return .channelSolo
        } else if text.contains("scene") {
            return .scene
        } else {
            return .channelFader
        }
    }
    
    private func extractInstrumentReferences(_ text: String) -> [String] {
        let instruments = ["kick", "snare", "hihat", "bass", "guitar", "piano", "vocal", "drums"]
        return instruments.filter { text.contains($0) }
    }
    
    private func findRecentSimilarCommands(_ text: String) -> [ProcessedVoiceCommand] {
        let recentCommands = commandHistory.suffix(10)
        return Array(recentCommands.filter { command in
            let similarity = calculateSimilarity(text, command.originalText)
            return similarity > 0.6
        })
    }
    
    private func assessCommandComplexity(_ text: String) -> CommandComplexity {
        let wordCount = text.components(separatedBy: .whitespaces).count
        let hasConjunctions = text.contains(" and ") || text.contains(" then ")
        
        if wordCount <= 3 {
            return .simple
        } else if wordCount <= 6 && !hasConjunctions {
            return .moderate
        } else {
            return .complex
        }
    }
    
    private func determineProcessorForInstrument(_ instrument: String) -> String {
        return "channel_processor" // Would be more sophisticated in real implementation
    }
    
    private func determineProcessorForCategory(_ category: CommandCategory) -> String {
        switch category {
        case .effects:
            return "effects_processor"
        case .routing:
            return "routing_processor"
        default:
            return "channel_processor"
        }
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        // Simple similarity calculation (would use more sophisticated algorithms in production)
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespaces))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespaces))
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func adaptProcessingStrategies(from command: ProcessedVoiceCommand) {
        // Analyze successful command patterns and adapt processing strategies
        // This would involve machine learning techniques in a full implementation
    }
    
    private func analyzeForInstrumentLabeling(_ text: String) -> ContextSuggestion? {
        // Check if text contains potential custom instrument references
        if text.contains("the ") && !instrumentLabels.keys.contains(where: { text.contains($0) }) {
            return ContextSuggestion(
                type: .instrumentLabeling,
                description: "Detected potential custom instrument reference. Consider adding instrument label.",
                confidence: 0.6,
                actionable: true
            )
        }
        return nil
    }
    
    private func setupPatternLearning() {
        // Initialize pattern learning engine with default patterns
        patternLearner.initialize()
    }
    
    private func loadSessionState() {
        if let savedContext = sessionStorage.loadSessionContext() {
            sessionContext = savedContext
        }
        
        if let savedLabels = sessionStorage.loadInstrumentLabels() {
            instrumentLabels = savedLabels
        }
    }
    
    private func saveSessionState() {
        sessionStorage.saveSessionContext(sessionContext)
        sessionStorage.saveInstrumentLabels(instrumentLabels)
    }
}

// MARK: - Supporting Data Structures

/// Context information for a processing session
struct SessionContext {
    var sessionId: UUID = UUID()
    var startTime: Date = Date()
    var totalCommands: Int = 0
    var successfulCommands: Int = 0
    var preferredProcessors: [String: Double] = [:]
    var userTerminology: [String: String] = [:]
    
    func merged(with other: SessionContext) -> SessionContext {
        var merged = self
        merged.totalCommands += other.totalCommands
        merged.successfulCommands += other.successfulCommands
        
        // Merge preferred processors
        for (processor, weight) in other.preferredProcessors {
            merged.preferredProcessors[processor] = (merged.preferredProcessors[processor] ?? 0.0) + weight
        }
        
        // Merge user terminology
        merged.userTerminology.merge(other.userTerminology) { _, new in new }
        
        return merged
    }
}

/// Custom instrument label information
struct InstrumentLabel {
    let userLabel: String
    let standardName: String
    let channelNumber: Int
    var confidence: Double
    var usageCount: Int
    var lastUsed: Date
}

/// Analysis result for current context
struct ContextAnalysis {
    let category: CommandCategory
    let instrumentReferences: [String]
    let recentSimilarCommands: [ProcessedVoiceCommand]
    let complexity: CommandComplexity
    let timestamp: Date
}

/// Instrument context information
struct InstrumentContext {
    let detectedInstruments: [String]
    let customLabelMatches: [String]
    let confidence: Double
}

/// Processing suggestion from context analysis
struct ProcessingSuggestion {
    let processorType: String
    let confidence: Double
    let reasoning: String
    let metadata: [String: Any]
}

/// Result of context-aware processing
struct ContextProcessingResult {
    let originalText: String
    let suggestions: [ProcessingSuggestion]
    let contextConfidence: Double
    let processingTimeMs: Double
    let sessionContext: SessionContext
    let instrumentContext: InstrumentContext
}

/// Context suggestion for improvement
struct ContextSuggestion {
    let type: ContextSuggestionType
    let description: String
    let confidence: Double
    let actionable: Bool
}

/// Types of context suggestions
enum ContextSuggestionType {
    case instrumentLabeling
    case patternLearning
    case contextEnhancement
    case processingOptimization
}

/// Command complexity levels
enum CommandComplexity {
    case simple
    case moderate
    case complex
}

/// Pattern suggestion from learning engine
struct PatternSuggestion {
    let recommendedProcessor: String
    let confidence: Double
    let reasoning: String
}

// MARK: - Pattern Learning Engine

/// Engine for learning user patterns and improving recognition
class PatternLearningEngine {
    private var patterns: [String: PatternData] = [:]
    private let minOccurrences = 3
    
    func initialize() {
        // Initialize with default patterns
    }
    
    func extractPatternsFrom(_ command: ProcessedVoiceCommand) {
        // Extract and store patterns from successful commands
        let text = command.originalText.lowercased()
        let key = generatePatternKey(text)
        
        if var pattern = patterns[key] {
            pattern.occurrences += 1
            pattern.lastSeen = Date()
            patterns[key] = pattern
        } else {
            patterns[key] = PatternData(
                pattern: text,
                occurrences: 1,
                processorUsed: command.processingMetadata.processorUsed,
                confidence: command.confidence,
                lastSeen: Date()
            )
        }
    }
    
    func suggestImprovedParsing(_ text: String, context: SessionContext) -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        let key = generatePatternKey(text.lowercased())
        
        // Check for exact pattern matches
        if let pattern = patterns[key], pattern.occurrences >= minOccurrences {
            suggestions.append(PatternSuggestion(
                recommendedProcessor: pattern.processorUsed,
                confidence: min(pattern.confidence * Double(pattern.occurrences) / 10.0, 1.0),
                reasoning: "Learned pattern from \(pattern.occurrences) similar commands"
            ))
        }
        
        // Check for partial pattern matches
        for (patternKey, patternData) in patterns {
            if patternKey != key && patternData.occurrences >= minOccurrences {
                let similarity = calculatePatternSimilarity(key, patternKey)
                if similarity > 0.7 {
                    suggestions.append(PatternSuggestion(
                        recommendedProcessor: patternData.processorUsed,
                        confidence: similarity * patternData.confidence,
                        reasoning: "Similar to learned pattern: \(patternData.pattern)"
                    ))
                }
            }
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    func suggestPatternImprovements(_ text: String, history: [ProcessedVoiceCommand]) -> [ContextSuggestion] {
        // Analyze patterns and suggest improvements
        return []
    }
    
    func reset() {
        patterns.removeAll()
    }
    
    private func generatePatternKey(_ text: String) -> String {
        // Generate a key that captures the essential pattern of the command
        let words = text.components(separatedBy: .whitespaces)
        let filteredWords = words.filter { !["the", "a", "an"].contains($0) }
        return filteredWords.joined(separator: " ")
    }
    
    private func calculatePatternSimilarity(_ pattern1: String, _ pattern2: String) -> Double {
        let words1 = Set(pattern1.components(separatedBy: .whitespaces))
        let words2 = Set(pattern2.components(separatedBy: .whitespaces))
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
}

/// Pattern data for learning
struct PatternData {
    let pattern: String
    var occurrences: Int
    let processorUsed: String
    let confidence: Double
    var lastSeen: Date
}

// MARK: - Session Storage

/// Handles persistence of session state and learned patterns
class SessionStorage {
    private let userDefaults = UserDefaults.standard
    private let contextKey = "voice_command_context"
    private let labelsKey = "instrument_labels"
    
    func saveSessionContext(_ context: SessionContext) {
        if let data = try? JSONEncoder().encode(context) {
            userDefaults.set(data, forKey: contextKey)
        }
    }
    
    func loadSessionContext() -> SessionContext? {
        guard let data = userDefaults.data(forKey: contextKey),
              let context = try? JSONDecoder().decode(SessionContext.self, from: data) else {
            return nil
        }
        return context
    }
    
    func saveInstrumentLabels(_ labels: [String: InstrumentLabel]) {
        if let data = try? JSONEncoder().encode(labels) {
            userDefaults.set(data, forKey: labelsKey)
        }
    }
    
    func loadInstrumentLabels() -> [String: InstrumentLabel]? {
        guard let data = userDefaults.data(forKey: labelsKey),
              let labels = try? JSONDecoder().decode([String: InstrumentLabel].self, from: data) else {
            return nil
        }
        return labels
    }
}

// MARK: - Codable Extensions

extension SessionContext: Codable {}
extension InstrumentLabel: Codable {}