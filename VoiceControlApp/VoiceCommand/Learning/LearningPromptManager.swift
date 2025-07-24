import Foundation
import SwiftUI

/// Manages brain emoji learning prompts with sequential display and network verification
@MainActor
class LearningPromptManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether a learning prompt is currently showing
    @Published var showingPrompt = false
    
    /// Current prompt data being displayed
    @Published var currentPromptData: LearningPromptData?
    
    /// Analytics for prompt interaction
    @Published private(set) var promptAnalytics = PromptAnalytics()
    
    // MARK: - Private Properties
    
    /// Queue of prompts waiting to be shown
    private var promptQueue: [LearningPromptData] = []
    
    /// Dictionary store for saving learning results
    private let dictionaryStore = PersonalDictionaryStore.shared
    
    /// Timer for auto-dismiss functionality
    private var dismissTimer: Timer?
    
    /// Time when current prompt was shown
    private var promptStartTime: Date?
    
    /// Learning analytics tracker
    private let analytics = LearningAnalytics.shared
    
    // MARK: - Configuration
    
    /// Auto-dismiss timeout (3 seconds as per PRP)
    private let autoDismissTimeout: TimeInterval = 3.0
    
    /// Minimum delay between sequential prompts
    private let sequentialPromptDelay: TimeInterval = 0.1
    
    // MARK: - Public Interface
    
    /// Show learning prompt(s) for similar commands
    /// - Parameter similarities: Array of similar command pairs
    func showPrompt(for similarities: [SimilarCommand]) {
        guard !similarities.isEmpty else { return }
        
        // Create prompt data for each similarity
        let prompts = similarities.map { similarity in
            LearningPromptData(
                id: UUID(),
                original: similarity.original,
                corrected: similarity.corrected,
                similarity: similarity.similarity,
                confidence: similarity.confidence,
                editDistance: similarity.editDistance,
                matchingWords: similarity.matchingWords,
                wasConsoleConnected: isConsoleConnected(),
                createdAt: Date()
            )
        }
        
        // Add to queue
        promptQueue.append(contentsOf: prompts)
        
        // Start showing prompts if not already showing
        if !showingPrompt {
            showNextPrompt()
        }
        
        // Update analytics
        promptAnalytics.totalPromptsQueued += prompts.count
        
        print("🧠 LearningPromptManager: Queued \(prompts.count) learning prompts")
    }
    
    /// Handle user accepting the learning prompt
    func handleAcceptResponse() {
        guard let promptData = currentPromptData else { return }
        
        let responseTime = promptStartTime?.timeIntervalSinceNow ?? 0
        handlePromptResponse(.accepted, responseTime: abs(responseTime), promptData: promptData)
    }
    
    /// Handle user rejecting the learning prompt
    func handleRejectResponse() {
        guard let promptData = currentPromptData else { return }
        
        let responseTime = promptStartTime?.timeIntervalSinceNow ?? 0
        handlePromptResponse(.rejected, responseTime: abs(responseTime), promptData: promptData)
    }
    
    /// Handle prompt being ignored (auto-dismissed)
    func handleIgnoredResponse() {
        guard let promptData = currentPromptData else { return }
        
        handlePromptResponse(.ignored, responseTime: autoDismissTimeout, promptData: promptData)
    }
    
    /// Force dismiss current prompt
    func dismissCurrentPrompt() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if showingPrompt {
            handleIgnoredResponse()
        }
    }
    
    /// Clear all queued prompts
    func clearQueue() {
        promptQueue.removeAll()
        dismissCurrentPrompt()
        
        print("🧠 LearningPromptManager: Cleared prompt queue")
    }
    
    /// Get current queue status
    func getQueueStatus() -> PromptQueueStatus {
        return PromptQueueStatus(
            currentlyShowing: showingPrompt,
            queuedCount: promptQueue.count,
            currentPrompt: currentPromptData
        )
    }
    
    // MARK: - Private Implementation
    
    /// Show the next prompt in the queue
    private func showNextPrompt() {
        guard !promptQueue.isEmpty, !showingPrompt else { return }
        
        let promptData = promptQueue.removeFirst()
        currentPromptData = promptData
        showingPrompt = true
        promptStartTime = Date()
        
        // Setup auto-dismiss timer
        setupAutoDismissTimer()
        
        // Update analytics
        promptAnalytics.totalPromptsShown += 1
        
        // Log prompt event
        analytics.logLearningEvent(
            original: promptData.original,
            corrected: promptData.corrected,
            similarity: promptData.similarity,
            wasConsoleConnected: promptData.wasConsoleConnected,
            eventType: .promptShown
        )
        
        print("🧠 LearningPromptManager: Showing prompt '\(promptData.original)' → '\(promptData.corrected)'")
    }
    
    /// Setup auto-dismiss timer for current prompt
    private func setupAutoDismissTimer() {
        dismissTimer?.invalidate()
        
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleAutoDismiss()
            }
        }
    }
    
    /// Handle auto-dismiss timeout
    private func handleAutoDismiss() {
        guard showingPrompt else { return }
        
        handleIgnoredResponse()
        print("🧠 LearningPromptManager: Auto-dismissed prompt after \(autoDismissTimeout) seconds")
    }
    
    /// Handle any prompt response (accepted, rejected, ignored)
    /// - Parameters:
    ///   - response: User's response
    ///   - responseTime: Time taken to respond
    ///   - promptData: The prompt data
    private func handlePromptResponse(_ response: LearningResponse, responseTime: TimeInterval, promptData: LearningPromptData) {
        // Cancel auto-dismiss timer
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        // Create dictionary entry
        let dictionaryEntry = PersonalDictionaryEntry(
            originalCommand: promptData.original,
            correctedCommand: promptData.corrected,
            confidence: promptData.confidence,
            wasConsoleConnected: promptData.wasConsoleConnected,
            userResponse: response
        )
        
        // Save to dictionary (only accepted responses contribute to learning)
        if response == .accepted {
            Task {
                try? await dictionaryStore.addEntry(dictionaryEntry)
            }
        }
        
        // Update analytics
        promptAnalytics.updateForResponse(response, responseTime: responseTime)
        
        // Log learning event
        analytics.logLearningEvent(
            original: promptData.original,
            corrected: promptData.corrected,
            similarity: promptData.similarity,
            wasConsoleConnected: promptData.wasConsoleConnected,
            eventType: .userResponse(response, responseTime)
        )
        
        // Clear current prompt
        showingPrompt = false
        currentPromptData = nil
        promptStartTime = nil
        
        // Show next prompt after brief delay
        if !promptQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + sequentialPromptDelay) {
                self.showNextPrompt()
            }
        }
        
        print("🧠 LearningPromptManager: User response \(response.emoji) in \(String(format: "%.2f", responseTime))s")
    }
    
    /// Check if console is currently connected for network verification
    /// - Returns: True if connected to console (not GUI)
    private func isConsoleConnected() -> Bool {
        // Check network settings to determine if we're connected to console vs GUI
        let networkSettings = NetworkSettings.shared
        
        // Must be connected to network and specifically to console (not GUI testing)
        return networkSettings.isValidConfiguration && 
               networkSettings.shouldSendToConsole &&
               networkSettings.connectionStatus == .connected("Yamaha Console")
    }
}

// MARK: - Supporting Data Structures

/// Data for a single learning prompt
struct LearningPromptData: Identifiable {
    let id: UUID
    let original: String
    let corrected: String
    let similarity: Double
    let confidence: Double
    let editDistance: Int
    let matchingWords: [String]
    let wasConsoleConnected: Bool
    let createdAt: Date
    
    /// Formatted similarity percentage
    var similarityPercentage: String {
        return "\(Int(similarity * 100))%"
    }
    
    /// Description for debugging
    var description: String {
        return "'\(original)' → '\(corrected)' (\(similarityPercentage) similar)"
    }
}

/// Analytics for prompt interactions
struct PromptAnalytics {
    var totalPromptsQueued = 0
    var totalPromptsShown = 0
    var acceptedCount = 0
    var rejectedCount = 0
    var ignoredCount = 0
    var averageResponseTime: Double = 0.0
    private var responseTimes: [Double] = []
    
    mutating func updateForResponse(_ response: LearningResponse, responseTime: Double) {
        switch response {
        case .accepted:
            acceptedCount += 1
        case .rejected:
            rejectedCount += 1
        case .ignored:
            ignoredCount += 1
        }
        
        // Update average response time
        responseTimes.append(responseTime)
        if responseTimes.count > 100 {
            responseTimes.removeFirst()
        }
        averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    /// Acceptance rate (0.0 - 1.0)
    var acceptanceRate: Double {
        let totalResponses = acceptedCount + rejectedCount + ignoredCount
        return totalResponses > 0 ? Double(acceptedCount) / Double(totalResponses) : 0.0
    }
    
    /// Engagement rate (responses vs ignores)
    var engagementRate: Double {
        let totalResponses = acceptedCount + rejectedCount + ignoredCount
        let activeResponses = acceptedCount + rejectedCount
        return totalResponses > 0 ? Double(activeResponses) / Double(totalResponses) : 0.0
    }
    
    var description: String {
        return """
        Learning Prompt Analytics:
        - Queued: \(totalPromptsQueued), Shown: \(totalPromptsShown)
        - Accepted: \(acceptedCount), Rejected: \(rejectedCount), Ignored: \(ignoredCount)
        - Acceptance rate: \(String(format: "%.1f", acceptanceRate * 100))%
        - Engagement rate: \(String(format: "%.1f", engagementRate * 100))%
        - Avg response time: \(String(format: "%.2f", averageResponseTime))s
        """
    }
}

/// Current status of the prompt queue
struct PromptQueueStatus {
    let currentlyShowing: Bool
    let queuedCount: Int
    let currentPrompt: LearningPromptData?
    
    var description: String {
        if currentlyShowing {
            return "Showing prompt, \(queuedCount) queued"
        } else {
            return "\(queuedCount) prompts queued"
        }
    }
}

// MARK: - Learning Analytics

/// Centralized analytics for learning events
class LearningAnalytics {
    static let shared = LearningAnalytics()
    
    private var events: [LearningEvent] = []
    private let maxEvents = 1000
    
    /// Log a learning event
    /// - Parameters:
    ///   - original: Original command text
    ///   - corrected: Corrected command text
    ///   - similarity: Similarity score
    ///   - wasConsoleConnected: Whether console was connected
    ///   - eventType: Type of event
    func logLearningEvent(
        original: String,
        corrected: String,
        similarity: Double,
        wasConsoleConnected: Bool,
        eventType: LearningEventType
    ) {
        let event = LearningEvent(
            id: UUID(),
            timestamp: Date(),
            originalCommand: original,
            correctedCommand: corrected,
            similarity: similarity,
            wasConsoleConnected: wasConsoleConnected,
            eventType: eventType
        )
        
        events.append(event)
        
        // Limit event history to prevent memory growth
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
    }
    
    /// Get recent learning events
    /// - Parameter limit: Maximum number of events to return
    /// - Returns: Array of recent events
    func getRecentEvents(limit: Int = 50) -> [LearningEvent] {
        return Array(events.suffix(limit))
    }
    
    /// Get learning statistics
    /// - Returns: Analytics about learning performance
    func getStatistics() -> LearningStatistics {
        let promptEvents = events.filter { event in
            if case .promptShown = event.eventType { return true }
            return false
        }
        
        let responseEvents = events.compactMap { event -> (LearningResponse, TimeInterval)? in
            if case .userResponse(let response, let time) = event.eventType {
                return (response, time)
            }
            return nil
        }
        
        let acceptedResponses = responseEvents.filter { $0.0 == .accepted }
        let avgResponseTime = responseEvents.isEmpty ? 0.0 : 
            responseEvents.reduce(0.0) { $0 + $1.1 } / Double(responseEvents.count)
        
        return LearningStatistics(
            totalPrompts: promptEvents.count,
            totalResponses: responseEvents.count,
            acceptedResponses: acceptedResponses.count,
            averageResponseTime: avgResponseTime,
            consoleConnectedEvents: events.filter { $0.wasConsoleConnected }.count
        )
    }
    
    /// Clear all events
    func clearHistory() {
        events.removeAll()
    }
}

/// Single learning event for analytics
struct LearningEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    let originalCommand: String
    let correctedCommand: String
    let similarity: Double
    let wasConsoleConnected: Bool
    let eventType: LearningEventType
}

/// Types of learning events
enum LearningEventType {
    case promptShown
    case userResponse(LearningResponse, TimeInterval)
    case similarityDetected(Double)
    case dictionaryUpdated
}

/// Learning statistics
struct LearningStatistics {
    let totalPrompts: Int
    let totalResponses: Int
    let acceptedResponses: Int
    let averageResponseTime: TimeInterval
    let consoleConnectedEvents: Int
    
    var acceptanceRate: Double {
        return totalResponses > 0 ? Double(acceptedResponses) / Double(totalResponses) : 0.0
    }
    
    var description: String {
        return """
        Learning System Statistics:
        - Total prompts shown: \(totalPrompts)
        - Total user responses: \(totalResponses)
        - Acceptance rate: \(String(format: "%.1f", acceptanceRate * 100))%
        - Average response time: \(String(format: "%.2f", averageResponseTime))s
        - Console-connected events: \(consoleConnectedEvents)
        """
    }
}

/// Turtle vs Rabbit mode configuration
enum VoiceMode {
    case turtle  // Manual send button
    case rabbit  // Auto-send
    
    /// Whether brain prompts should appear immediately after send
    var showsImmediatePrompts: Bool {
        switch self {
        case .turtle:
            return true  // Show after manual send button tap
        case .rabbit:
            return true  // Show immediately after auto-send
        }
    }
}

// MARK: - NetworkSettings Extension

/// Extension to support learning network verification
extension NetworkSettings {
    // NetworkSettings already has connectionStatus property and ConnectionStatus enum
    // No additional implementation needed - using existing properties
}