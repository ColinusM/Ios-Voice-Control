import XCTest
@testable import VoiceControlApp

final class SimilarityDetectionTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var similarityDetector: SimilarityDetector!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        similarityDetector = SimilarityDetector()
    }
    
    override func tearDownWithError() throws {
        similarityDetector = nil
        super.tearDown()
    }
    
    // MARK: - Levenshtein Distance Tests
    
    func testLevenshteinDistance_identicalStrings() throws {
        let distance = SimilarityDetector.levenshteinDistance("hello", "hello")
        XCTAssertEqual(distance, 0, "Identical strings should have distance 0")
    }
    
    func testLevenshteinDistance_emptyStrings() throws {
        let distance1 = SimilarityDetector.levenshteinDistance("", "")
        let distance2 = SimilarityDetector.levenshteinDistance("test", "")
        let distance3 = SimilarityDetector.levenshteinDistance("", "test")
        
        XCTAssertEqual(distance1, 0, "Empty strings should have distance 0")
        XCTAssertEqual(distance2, 4, "Distance to empty string should equal string length")
        XCTAssertEqual(distance3, 4, "Distance from empty string should equal string length")
    }
    
    func testLevenshteinDistance_singleCharacterDifference() throws {
        let distance = SimilarityDetector.levenshteinDistance("cat", "bat")
        XCTAssertEqual(distance, 1, "Single character substitution should have distance 1")
    }
    
    func testLevenshteinDistance_insertion() throws {
        let distance = SimilarityDetector.levenshteinDistance("cat", "cats")
        XCTAssertEqual(distance, 1, "Single character insertion should have distance 1")
    }
    
    func testLevenshteinDistance_deletion() throws {
        let distance = SimilarityDetector.levenshteinDistance("cats", "cat")
        XCTAssertEqual(distance, 1, "Single character deletion should have distance 1")
    }
    
    func testLevenshteinDistance_complexTransformation() throws {
        let distance = SimilarityDetector.levenshteinDistance("kitten", "sitting")
        XCTAssertEqual(distance, 3, "kitten->sitting should have distance 3")
    }
    
    // MARK: - Similarity Score Tests
    
    func testSimilarityScore_identicalStrings() throws {
        let similarity = similarityDetector.calculateSimilarity("hello", "hello")
        XCTAssertEqual(similarity, 1.0, accuracy: 0.001, "Identical strings should have similarity 1.0")
    }
    
    func testSimilarityScore_completelyDifferent() throws {
        let similarity = similarityDetector.calculateSimilarity("abc", "xyz")
        XCTAssertLessThan(similarity, 0.5, "Completely different strings should have low similarity")
    }
    
    func testSimilarityScore_partialMatch() throws {
        let similarity = similarityDetector.calculateSimilarity("hello world", "hello there")
        XCTAssertGreaterThan(similarity, 0.5, "Partially matching strings should have moderate similarity")
        XCTAssertLessThan(similarity, 1.0, "Partially matching strings should not have perfect similarity")
    }
    
    func testSimilarityScore_caseInsensitive() throws {
        let similarity1 = similarityDetector.calculateSimilarity("Hello", "hello")
        let similarity2 = similarityDetector.calculateSimilarity("HELLO", "hello")
        
        XCTAssertEqual(similarity1, 1.0, accuracy: 0.001, "Case differences should be ignored")
        XCTAssertEqual(similarity2, 1.0, accuracy: 0.001, "Case differences should be ignored")
    }
    
    // MARK: - Similar Command Detection Tests
    
    func testFindSimilarCommands_noSimilarCommands() throws {
        let input = "turn on lights"
        let dictionary = ["mute channel 1", "set volume to 50", "unmute all channels"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.7
        )
        
        XCTAssertTrue(similarCommands.isEmpty, "Should find no similar commands when none exist")
    }
    
    func testFindSimilarCommands_withSimilarCommands() throws {
        let input = "mute channel one"
        let dictionary = ["mute channel 1", "mute channel 2", "unmute channel 1", "set volume"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.6
        )
        
        XCTAssertFalse(similarCommands.isEmpty, "Should find similar commands")
        XCTAssertTrue(similarCommands.contains { $0.corrected == "mute channel 1" }, 
                     "Should find 'mute channel 1' as similar")
    }
    
    func testFindSimilarCommands_sortedBySimilarity() throws {
        let input = "mute channel one"
        let dictionary = ["mute channel 1", "mute channel 2", "mute all channels"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.5
        )
        
        // Verify results are sorted by similarity (highest first)
        for i in 0..<(similarCommands.count - 1) {
            XCTAssertGreaterThanOrEqual(
                similarCommands[i].similarity,
                similarCommands[i + 1].similarity,
                "Results should be sorted by similarity in descending order"
            )
        }
    }
    
    func testFindSimilarCommands_thresholdFiltering() throws {
        let input = "test"
        let dictionary = ["test", "testing", "completely different string"]
        
        let highThreshold = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.9
        )
        
        let lowThreshold = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.3
        )
        
        XCTAssertLessThanOrEqual(highThreshold.count, lowThreshold.count, 
                                "Higher threshold should return fewer or equal results")
    }
    
    // MARK: - Performance Tests
    
    func testSimilarityDetection_performance() throws {
        let input = "mute channel one"
        let largeDictionary = Array(1...1000).map { "command \($0)" }
        
        measure {
            let _ = similarityDetector.findSimilarCommands(
                input: input,
                in: largeDictionary,
                threshold: 0.7
            )
        }
        
        // Performance should be under 100ms as specified in PRP
        let startTime = CFAbsoluteTimeGetCurrent()
        let _ = similarityDetector.findSimilarCommands(
            input: input,
            in: largeDictionary,
            threshold: 0.7
        )
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(timeElapsed, 0.1, "Similarity detection should complete in under 100ms")
    }
    
    func testLevenshteinDistance_performance() throws {
        let string1 = String(repeating: "a", count: 100)
        let string2 = String(repeating: "b", count: 100)
        
        measure {
            let _ = SimilarityDetector.levenshteinDistance(string1, string2)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testSimilarityDetection_emptyInput() throws {
        let dictionary = ["test", "another test"]
        let similarCommands = similarityDetector.findSimilarCommands(
            input: "",
            in: dictionary,
            threshold: 0.7
        )
        
        XCTAssertTrue(similarCommands.isEmpty, "Empty input should return no similar commands")
    }
    
    func testSimilarityDetection_emptyDictionary() throws {
        let similarCommands = similarityDetector.findSimilarCommands(
            input: "test",
            in: [],
            threshold: 0.7
        )
        
        XCTAssertTrue(similarCommands.isEmpty, "Empty dictionary should return no similar commands")
    }
    
    func testSimilarityDetection_specialCharacters() throws {
        let input = "mute ch@nnel 1"
        let dictionary = ["mute channel 1", "mute channel 2"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.8
        )
        
        XCTAssertFalse(similarCommands.isEmpty, "Should handle special characters gracefully")
    }
    
    func testSimilarityDetection_unicodeCharacters() throws {
        let input = "müte channel 1"
        let dictionary = ["mute channel 1", "mute channel 2"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.8
        )
        
        XCTAssertFalse(similarCommands.isEmpty, "Should handle unicode characters gracefully")
    }
    
    // MARK: - Confidence Score Tests
    
    func testConfidenceScore_highSimilarity() throws {
        let input = "mute channel 1"
        let dictionary = ["mute channel 1"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.5
        )
        
        XCTAssertFalse(similarCommands.isEmpty)
        XCTAssertGreaterThan(similarCommands[0].confidence, 0.9, 
                           "High similarity should result in high confidence")
    }
    
    func testConfidenceScore_lowSimilarity() throws {
        let input = "mute"
        let dictionary = ["mute channel 1"]
        
        let similarCommands = similarityDetector.findSimilarCommands(
            input: input,
            in: dictionary,
            threshold: 0.3
        )
        
        XCTAssertFalse(similarCommands.isEmpty)
        XCTAssertLessThan(similarCommands[0].confidence, 0.7, 
                         "Low similarity should result in lower confidence")
    }
}