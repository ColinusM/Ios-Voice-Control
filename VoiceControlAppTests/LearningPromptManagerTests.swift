import XCTest
@testable import VoiceControlApp

@MainActor
final class LearningPromptManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var learningPromptManager: LearningPromptManager!
    var mockSimilarCommands: [SimilarCommand]!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        learningPromptManager = LearningPromptManager()
        
        // Create mock similar commands
        mockSimilarCommands = [
            SimilarCommand(
                original: "mute channel one",
                corrected: "mute channel 1",
                similarity: 0.95,
                confidence: 0.92,
                editDistance: 2,
                matchingWords: ["mute", "channel"]
            ),
            SimilarCommand(
                original: "turn up volume",
                corrected: "increase volume",
                similarity: 0.85,
                confidence: 0.78,
                editDistance: 5,
                matchingWords: ["volume"]
            )
        ]
    }
    
    override func tearDownWithError() throws {
        learningPromptManager = nil
        mockSimilarCommands = nil
        super.tearDown()
    }
    
    // MARK: - Prompt Queue Tests
    
    func testShowPrompt_withSimilarCommands() throws {
        // Initially no prompts showing
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
        
        // Show prompts
        learningPromptManager.showPrompt(for: mockSimilarCommands)
        
        // Should start showing first prompt
        XCTAssertTrue(learningPromptManager.showingPrompt)
        XCTAssertNotNil(learningPromptManager.currentPromptData)
        XCTAssertEqual(learningPromptManager.currentPromptData?.original, "mute channel one")
    }
    
    func testShowPrompt_withEmptyArray() throws {
        learningPromptManager.showPrompt(for: [])
        
        // Should not show any prompts
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    func testQueueStatus_initialState() throws {
        let status = learningPromptManager.getQueueStatus()
        
        XCTAssertFalse(status.currentlyShowing)
        XCTAssertEqual(status.queuedCount, 0)
        XCTAssertNil(status.currentPrompt)
    }
    
    func testQueueStatus_withQueuedPrompts() throws {
        learningPromptManager.showPrompt(for: mockSimilarCommands)
        let status = learningPromptManager.getQueueStatus()
        
        XCTAssertTrue(status.currentlyShowing)
        XCTAssertEqual(status.queuedCount, 1) // One remaining in queue
        XCTAssertNotNil(status.currentPrompt)
    }
    
    // MARK: - User Response Tests
    
    func testHandleAcceptResponse() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        // Verify prompt is showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        
        // Accept the prompt
        learningPromptManager.handleAcceptResponse()
        
        // Should clear current prompt
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    func testHandleRejectResponse() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        // Verify prompt is showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        
        // Reject the prompt
        learningPromptManager.handleRejectResponse()
        
        // Should clear current prompt
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    func testHandleIgnoredResponse() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        // Verify prompt is showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        
        // Ignore the prompt
        learningPromptManager.handleIgnoredResponse()
        
        // Should clear current prompt
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    // MARK: - Sequential Prompt Tests
    
    func testSequentialPrompts() throws {
        learningPromptManager.showPrompt(for: mockSimilarCommands)
        
        // First prompt should be showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        XCTAssertEqual(learningPromptManager.currentPromptData?.original, "mute channel one")
        
        // Accept first prompt
        learningPromptManager.handleAcceptResponse()
        
        // Wait a bit for sequential delay
        let expectation = expectation(description: "Sequential prompt delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Second prompt should now be showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        XCTAssertEqual(learningPromptManager.currentPromptData?.original, "turn up volume")
    }
    
    // MARK: - Clear Queue Tests
    
    func testClearQueue() throws {
        learningPromptManager.showPrompt(for: mockSimilarCommands)
        
        // Verify prompts are queued and showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        let status = learningPromptManager.getQueueStatus()
        XCTAssertGreaterThan(status.queuedCount, 0)
        
        // Clear the queue
        learningPromptManager.clearQueue()
        
        // Should clear everything
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
        
        let clearedStatus = learningPromptManager.getQueueStatus()
        XCTAssertEqual(clearedStatus.queuedCount, 0)
    }
    
    func testDismissCurrentPrompt() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        // Verify prompt is showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        
        // Dismiss current prompt
        learningPromptManager.dismissCurrentPrompt()
        
        // Should clear current prompt
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    // MARK: - Analytics Tests
    
    func testPromptAnalytics_initialState() throws {
        let analytics = learningPromptManager.promptAnalytics
        
        XCTAssertEqual(analytics.totalPromptsQueued, 0)
        XCTAssertEqual(analytics.totalPromptsShown, 0)
        XCTAssertEqual(analytics.acceptedCount, 0)
        XCTAssertEqual(analytics.rejectedCount, 0)
        XCTAssertEqual(analytics.ignoredCount, 0)
        XCTAssertEqual(analytics.acceptanceRate, 0.0)
        XCTAssertEqual(analytics.engagementRate, 0.0)
    }
    
    func testPromptAnalytics_afterShowingPrompts() throws {
        learningPromptManager.showPrompt(for: mockSimilarCommands)
        
        let analytics = learningPromptManager.promptAnalytics
        XCTAssertEqual(analytics.totalPromptsQueued, 2)
        XCTAssertEqual(analytics.totalPromptsShown, 1) // Only one shown initially
    }
    
    func testPromptAnalytics_afterUserResponses() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        learningPromptManager.handleAcceptResponse()
        
        let analytics = learningPromptManager.promptAnalytics
        XCTAssertEqual(analytics.acceptedCount, 1)
        XCTAssertGreaterThan(analytics.acceptanceRate, 0.0)
        XCTAssertGreaterThan(analytics.engagementRate, 0.0)
    }
    
    // MARK: - Learning Event Tests
    
    func testLearningEvents_promptShown() throws {
        let analytics = LearningAnalytics.shared
        let initialEventCount = analytics.getRecentEvents().count
        
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        let newEventCount = analytics.getRecentEvents().count
        XCTAssertGreaterThan(newEventCount, initialEventCount, "Should log prompt shown event")
    }
    
    func testLearningEvents_userResponse() throws {
        let analytics = LearningAnalytics.shared
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        let initialEventCount = analytics.getRecentEvents().count
        learningPromptManager.handleAcceptResponse()
        
        let newEventCount = analytics.getRecentEvents().count
        XCTAssertGreaterThan(newEventCount, initialEventCount, "Should log user response event")
    }
    
    // MARK: - Data Structure Tests
    
    func testLearningPromptData_similarityPercentage() throws {
        let promptData = LearningPromptData(
            id: UUID(),
            original: "test",
            corrected: "test command",
            similarity: 0.85,
            confidence: 0.80,
            editDistance: 2,
            matchingWords: ["test"],
            wasConsoleConnected: false,
            createdAt: Date()
        )
        
        XCTAssertEqual(promptData.similarityPercentage, "85%")
    }
    
    func testLearningPromptData_description() throws {
        let promptData = LearningPromptData(
            id: UUID(),
            original: "mute ch1",
            corrected: "mute channel 1",
            similarity: 0.90,
            confidence: 0.85,
            editDistance: 3,
            matchingWords: ["mute"],
            wasConsoleConnected: true,
            createdAt: Date()
        )
        
        let description = promptData.description
        XCTAssertTrue(description.contains("mute ch1"))
        XCTAssertTrue(description.contains("mute channel 1"))
        XCTAssertTrue(description.contains("90%"))
    }
    
    // MARK: - Auto-Dismiss Tests
    
    func testAutoDismiss_timeout() throws {
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        // Verify prompt is showing
        XCTAssertTrue(learningPromptManager.showingPrompt)
        
        // Wait for auto-dismiss timeout (3 seconds + buffer)
        let expectation = expectation(description: "Auto-dismiss timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should be auto-dismissed
        XCTAssertFalse(learningPromptManager.showingPrompt)
        XCTAssertNil(learningPromptManager.currentPromptData)
    }
    
    // MARK: - Network Connection Tests
    
    func testNetworkConnectedPrompt() throws {
        // Test that prompt data includes network connection status
        learningPromptManager.showPrompt(for: [mockSimilarCommands[0]])
        
        guard let promptData = learningPromptManager.currentPromptData else {
            XCTFail("No prompt data available")
            return
        }
        
        // Network connection status should be captured
        // In test environment, this will typically be false
        XCTAssertNotNil(promptData.wasConsoleConnected)
    }
}

// MARK: - Mock Extensions

extension SimilarCommand {
    /// Create a mock similar command for testing
    static func mock(
        original: String = "test original",
        corrected: String = "test corrected",
        similarity: Double = 0.85,
        confidence: Double = 0.80
    ) -> SimilarCommand {
        return SimilarCommand(
            original: original,
            corrected: corrected,
            similarity: similarity,
            confidence: confidence,
            editDistance: 2,
            matchingWords: ["test"]
        )
    }
}