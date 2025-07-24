import Foundation

/// High-performance similarity detection engine for voice command learning
/// Optimized for <100ms performance with word-level Levenshtein distance
class SimilarityEngine {
    
    // MARK: - Configuration
    
    /// Minimum words for similarity comparison (exception: "mute channel X" = 3 words)
    private let minimumWords = 3
    
    /// Maximum word count difference for early exit optimization
    private let maxWordCountDifference = 2
    
    /// Performance monitoring
    private var processingTimes: [Double] = []
    
    // MARK: - Public Interface
    
    /// Calculate similarity between two voice commands
    /// - Parameters:
    ///   - command1: First command text
    ///   - command2: Second command text
    /// - Returns: Similarity result with distance and match status
    func calculateSimilarity(_ command1: String, _ command2: String) -> SimilarityResult {
        let startTime = Date()
        
        // Normalize and tokenize commands
        let words1 = tokenizeCommand(command1)
        let words2 = tokenizeCommand(command2)
        
        // Early exit if commands are too different in length
        if abs(words1.count - words2.count) > maxWordCountDifference {
            recordProcessingTime(startTime)
            return .noMatch
        }
        
        // Skip if either command is too short (with exception for mute commands)
        if !isValidCommandLength(words1) || !isValidCommandLength(words2) {
            recordProcessingTime(startTime)
            return .noMatch
        }
        
        // Calculate edit distance at word level
        let distance = levenshteinDistance(words1, words2)
        
        // Determine threshold based on word count
        let threshold = getThreshold(for: words1.count)
        
        recordProcessingTime(startTime)
        
        if distance <= threshold {
            let similarity = calculateSimilarityScore(distance: distance, maxWords: max(words1.count, words2.count))
            return .match(distance: distance, similarity: similarity, matchingWords: findMatchingWords(words1, words2))
        } else {
            return .noMatch
        }
    }
    
    /// Find all similar commands from a list of recent commands
    /// - Parameters:
    ///   - currentCommand: The current successful command
    ///   - recentCommands: List of recent commands to compare against
    /// - Returns: Array of similar command pairs
    func findSimilarCommands(_ currentCommand: ProcessedVoiceCommand, _ recentCommands: [ProcessedVoiceCommand]) -> [SimilarCommand] {
        let startTime = Date()
        var similarCommands: [SimilarCommand] = []
        
        // Compare against all recent commands, not just the immediate previous
        for recentCommand in recentCommands.reversed() { // Start with most recent
            // Skip if same command or too recent (within 1 second)
            if recentCommand.id == currentCommand.id || 
               currentCommand.timestamp.timeIntervalSince(recentCommand.timestamp) < 1.0 {
                continue
            }
            
            let result = calculateSimilarity(currentCommand.originalText, recentCommand.originalText)
            
            if case .match(let distance, let similarityScore, let matchingWords) = result {
                let similarCommand = SimilarCommand(
                    original: recentCommand.originalText,
                    corrected: currentCommand.originalText,
                    editDistance: distance,
                    similarity: similarityScore,
                    matchingWords: matchingWords,
                    confidence: calculateConfidence(similarity: similarityScore, currentConfidence: currentCommand.confidence),
                    originalTimestamp: recentCommand.timestamp,
                    correctedTimestamp: currentCommand.timestamp
                )
                similarCommands.append(similarCommand)
            }
        }
        
        recordProcessingTime(startTime)
        return similarCommands.sorted { $0.confidence > $1.confidence }
    }
    
    /// Check if two commands are similar (public convenience method)
    /// - Parameters:
    ///   - command1: First command
    ///   - command2: Second command
    /// - Returns: True if commands are similar
    func areSimilar(_ command1: String, _ command2: String) -> Bool {
        if case .match = calculateSimilarity(command1, command2) {
            return true
        }
        return false
    }
    
    /// Get average processing time for performance monitoring
    /// - Returns: Average processing time in milliseconds
    func getAverageProcessingTime() -> Double {
        guard !processingTimes.isEmpty else { return 0.0 }
        return processingTimes.reduce(0, +) / Double(processingTimes.count)
    }
    
    /// Reset performance statistics
    func resetPerformanceStats() {
        processingTimes.removeAll()
    }
    
    // MARK: - Private Implementation
    
    /// Tokenize command into normalized words
    /// - Parameter command: Raw command text
    /// - Returns: Array of normalized words
    private func tokenizeCommand(_ command: String) -> [String] {
        return command
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { word in
                // Normalize common variations
                return normalizeWord(word)
            }
    }
    
    /// Normalize individual words for better matching
    /// - Parameter word: Word to normalize
    /// - Returns: Normalized word
    private func normalizeWord(_ word: String) -> String {
        // Remove punctuation
        let cleanWord = word.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        
        // Common audio engineering normalizations
        let normalizations: [String: String] = [
            "db": "dB",
            "minus": "-",
            "negative": "-",
            "plus": "+",
            "positive": "+",
            "centre": "center",
            "reverb": "reverb",
            "delay": "delay",
            "compressor": "comp",
            "compression": "comp"
        ]
        
        return normalizations[cleanWord] ?? cleanWord
    }
    
    /// Check if command has valid length for similarity comparison
    /// - Parameter words: Tokenized words
    /// - Returns: True if valid length
    private func isValidCommandLength(_ words: [String]) -> Bool {
        // Exception for mute commands (3 words minimum)
        if words.count == 3 && words.contains("mute") && words.contains("channel") {
            return true
        }
        
        // General minimum of 4 words
        return words.count >= minimumWords + 1
    }
    
    /// Get similarity threshold based on word count
    /// - Parameter wordCount: Number of words in command
    /// - Returns: Maximum allowed edit distance
    private func getThreshold(for wordCount: Int) -> Int {
        if wordCount <= 5 {
            // n-1 threshold for 4-5 words (75-80% similarity)
            return wordCount - 1
        } else {
            // n-2 threshold for 6+ words (67%+ similarity)
            return wordCount - 2
        }
    }
    
    /// Optimized word-level Levenshtein distance calculation
    /// - Parameters:
    ///   - words1: First command's words
    ///   - words2: Second command's words
    /// - Returns: Edit distance between word sequences
    private func levenshteinDistance(_ words1: [String], _ words2: [String]) -> Int {
        let len1 = words1.count
        let len2 = words2.count
        
        // Early exit for identical commands
        if words1 == words2 { return 0 }
        
        // Handle empty sequences
        if len1 == 0 { return len2 }
        if len2 == 0 { return len1 }
        
        // Use single array optimization for memory efficiency
        var previousRow = Array(0...len2)
        var currentRow = Array(repeating: 0, count: len2 + 1)
        
        for i in 1...len1 {
            currentRow[0] = i
            
            for j in 1...len2 {
                let cost = (words1[i-1] == words2[j-1]) ? 0 : 1
                
                currentRow[j] = min(
                    previousRow[j] + 1,      // deletion
                    currentRow[j-1] + 1,     // insertion
                    previousRow[j-1] + cost  // substitution
                )
            }
            
            // Swap rows
            (previousRow, currentRow) = (currentRow, previousRow)
        }
        
        return previousRow[len2]
    }
    
    /// Calculate similarity score from edit distance
    /// - Parameters:
    ///   - distance: Edit distance
    ///   - maxWords: Maximum word count between the two commands
    /// - Returns: Similarity score (0.0 - 1.0)
    private func calculateSimilarityScore(distance: Int, maxWords: Int) -> Double {
        guard maxWords > 0 else { return 0.0 }
        return max(0.0, 1.0 - (Double(distance) / Double(maxWords)))
    }
    
    /// Find words that match between two command sequences
    /// - Parameters:
    ///   - words1: First command's words
    ///   - words2: Second command's words
    /// - Returns: Array of matching words
    private func findMatchingWords(_ words1: [String], _ words2: [String]) -> [String] {
        let set1 = Set(words1)
        let set2 = Set(words2)
        return Array(set1.intersection(set2))
    }
    
    /// Calculate confidence score for a similar command pair
    /// - Parameters:
    ///   - similarity: Similarity score (0.0 - 1.0)
    ///   - currentConfidence: Confidence of the current successful command
    /// - Returns: Combined confidence score
    private func calculateConfidence(similarity: Double, currentConfidence: Double) -> Double {
        // Weight similarity and current command confidence
        return (similarity * 0.7) + (currentConfidence * 0.3)
    }
    
    /// Record processing time for performance monitoring
    /// - Parameter startTime: When processing started
    private func recordProcessingTime(_ startTime: Date) {
        let processingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        processingTimes.append(processingTime)
        
        // Keep only last 100 measurements to avoid memory growth
        if processingTimes.count > 100 {
            processingTimes.removeFirst()
        }
        
        // Log if processing time exceeds threshold
        if processingTime > 100.0 {
            print("⚠️ SimilarityEngine: Processing time exceeded 100ms: \(String(format: "%.2f", processingTime))ms")
        }
    }
}

// MARK: - Supporting Data Structures

/// Result of similarity calculation
enum SimilarityResult {
    case match(distance: Int, similarity: Double, matchingWords: [String])
    case noMatch
    
    var isMatch: Bool {
        switch self {
        case .match:
            return true
        case .noMatch:
            return false
        }
    }
}

/// Similar command pair for learning
struct SimilarCommand: Identifiable {
    let id = UUID()
    let original: String
    let corrected: String
    let editDistance: Int
    let similarity: Double
    let matchingWords: [String]
    let confidence: Double
    let originalTimestamp: Date
    let correctedTimestamp: Date
    
    /// Time between original attempt and correction
    var correctionDelay: TimeInterval {
        return correctedTimestamp.timeIntervalSince(originalTimestamp)
    }
    
    /// Description for debugging
    var description: String {
        return "'\(original)' → '\(corrected)' (distance: \(editDistance), similarity: \(String(format: "%.2f", similarity)))"
    }
}

// MARK: - Performance Extensions

extension SimilarityEngine {
    
    /// Performance metrics for monitoring
    struct PerformanceMetrics {
        let averageProcessingTime: Double
        let maxProcessingTime: Double
        let minProcessingTime: Double
        let totalComparisons: Int
        let exceededThresholdCount: Int
        
        var description: String {
            return """
            SimilarityEngine Performance:
            - Average: \(String(format: "%.2f", averageProcessingTime))ms
            - Max: \(String(format: "%.2f", maxProcessingTime))ms
            - Min: \(String(format: "%.2f", minProcessingTime))ms
            - Total comparisons: \(totalComparisons)
            - Exceeded 100ms: \(exceededThresholdCount) times
            """
        }
    }
    
    /// Get detailed performance metrics
    /// - Returns: Performance metrics structure
    func getPerformanceMetrics() -> PerformanceMetrics {
        guard !processingTimes.isEmpty else {
            return PerformanceMetrics(
                averageProcessingTime: 0,
                maxProcessingTime: 0,
                minProcessingTime: 0,
                totalComparisons: 0,
                exceededThresholdCount: 0
            )
        }
        
        return PerformanceMetrics(
            averageProcessingTime: processingTimes.reduce(0, +) / Double(processingTimes.count),
            maxProcessingTime: processingTimes.max() ?? 0,
            minProcessingTime: processingTimes.min() ?? 0,
            totalComparisons: processingTimes.count,
            exceededThresholdCount: processingTimes.filter { $0 > 100.0 }.count
        )
    }
}