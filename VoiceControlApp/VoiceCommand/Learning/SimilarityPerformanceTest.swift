import Foundation

/// Performance test utility for similarity detection algorithms
/// Tests the SimilarityEngine to ensure <100ms performance requirement
class SimilarityPerformanceTest {
    
    private let similarityEngine = SimilarityEngine()
    
    /// Run comprehensive performance tests for similarity detection
    /// - Returns: Performance test results
    func runPerformanceTests() -> PerformanceTestResults {
        let startTime = Date()
        var individualTests: [IndividualTestResult] = []
        
        print("🚀 Starting SimilarityEngine Performance Tests...")
        
        // Test 1: Single similarity comparison
        let singleTest = testSingleSimilarityComparison()
        individualTests.append(singleTest)
        
        // Test 2: Batch similarity detection (realistic scenario)
        let batchTest = testBatchSimilarityDetection()
        individualTests.append(batchTest)
        
        // Test 3: Large dataset similarity search
        let largeDatasetTest = testLargeDatasetSimilarity()
        individualTests.append(largeDatasetTest)
        
        // Test 4: Edge cases and complex strings
        let edgeCasesTest = testEdgeCases()
        individualTests.append(edgeCasesTest)
        
        let totalTime = Date().timeIntervalSince(startTime) * 1000
        
        let results = PerformanceTestResults(
            totalTestTimeMs: totalTime,
            individualTests: individualTests,
            passed: individualTests.allSatisfy { $0.passed },
            averageLatency: individualTests.map { $0.averageLatencyMs }.reduce(0, +) / Double(individualTests.count)
        )
        
        printResults(results)
        return results
    }
    
    // MARK: - Individual Test Methods
    
    /// Test single similarity comparison performance
    private func testSingleSimilarityComparison() -> IndividualTestResult {
        let testCases = [
            ("set channel one to minus six", "set channel 1 to -6 db"),
            ("mute the kick drum", "mute kick"),
            ("add reverb to vocals", "set vocal reverb on"),
            ("turn up the bass guitar", "increase bass level"),
            ("recall scene three", "load scene 3")
        ]
        
        var latencies: [Double] = []
        var similarities: [Double] = []
        
        for (original, corrected) in testCases {
            let startTime = Date()
            let similarity = similarityEngine.calculateSimilarity(original, corrected)
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            latencies.append(latency)
            similarities.append(similarity)
        }
        
        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        let averageSimilarity = similarities.reduce(0, +) / Double(similarities.count)
        
        return IndividualTestResult(
            testName: "Single Similarity Comparison",
            averageLatencyMs: averageLatency,
            maxLatencyMs: maxLatency,
            testCount: testCases.count,
            passed: maxLatency < 10.0, // Single comparisons should be <10ms
            details: "Avg similarity: \(String(format: "%.3f", averageSimilarity))"
        )
    }
    
    /// Test batch similarity detection (realistic user scenario)
    private func testBatchSimilarityDetection() -> IndividualTestResult {
        // Simulate a successful command with 5 recent failed commands
        let successfulCommand = createMockCommand("set channel one to minus six db", confidence: 0.9)
        let recentFailures = [
            createMockCommand("set channel one to six", confidence: 0.3),
            createMockCommand("channel one minus six", confidence: 0.4),
            createMockCommand("set one to minus six db", confidence: 0.5),
            createMockCommand("set channel to minus six", confidence: 0.4),
            createMockCommand("channel one to six db", confidence: 0.6)
        ]
        
        var latencies: [Double] = []
        
        // Run 20 iterations to get reliable performance data
        for _ in 0..<20 {
            let startTime = Date()
            let similarities = similarityEngine.findSimilarCommands(successfulCommand, recentFailures)
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            latencies.append(latency)
        }
        
        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        
        return IndividualTestResult(
            testName: "Batch Similarity Detection",
            averageLatencyMs: averageLatency,
            maxLatencyMs: maxLatency,
            testCount: 20,
            passed: averageLatency < 100.0, // Must meet <100ms requirement
            details: "1 vs 5 command comparison"
        )
    }
    
    /// Test performance with larger dataset (10 vs 20 commands)
    private func testLargeDatasetSimilarity() -> IndividualTestResult {
        let successfulCommands = [
            createMockCommand("set channel one to minus six db", confidence: 0.9),
            createMockCommand("mute the kick drum", confidence: 0.8),
            createMockCommand("add reverb to vocals", confidence: 0.85),
            createMockCommand("turn up bass guitar", confidence: 0.75),
            createMockCommand("recall scene three", confidence: 0.95),
            createMockCommand("solo the snare drum", confidence: 0.8),
            createMockCommand("pan guitar left", confidence: 0.7),
            createMockCommand("cut high frequencies on bass", confidence: 0.8),
            createMockCommand("increase vocal level", confidence: 0.9),
            createMockCommand("add delay to guitar", confidence: 0.75)
        ]
        
        let recentFailures = Array(0..<20).map { i in
            createMockCommand("command variant \(i)", confidence: Double.random(in: 0.2...0.6))
        }
        
        var latencies: [Double] = []
        
        // Test each successful command against all failures
        for successfulCommand in successfulCommands {
            let startTime = Date()
            let _ = similarityEngine.findSimilarCommands(successfulCommand, recentFailures)
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            latencies.append(latency)
        }
        
        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        
        return IndividualTestResult(
            testName: "Large Dataset Similarity",
            averageLatencyMs: averageLatency,
            maxLatencyMs: maxLatency,
            testCount: successfulCommands.count,
            passed: averageLatency < 100.0, // Still must meet <100ms requirement
            details: "10 vs 20 command comparison"
        )
    }
    
    /// Test edge cases and complex strings
    private func testEdgeCases() -> IndividualTestResult {
        let edgeCases = [
            // Very short strings
            ("a", "b"),
            ("", "test"),
            
            // Very long strings
            ("set the channel number one fader level to minus six point five decibels and add some reverb", 
             "channel 1 to -6.5 db with reverb"),
            
            // Special characters and numbers
            ("ch@nnel 1 -> -6dB", "channel one to minus six db"),
            
            // Mixed case and spacing
            ("SET    CHANNEL     ONE", "set channel 1"),
            
            // Similar but different meanings
            ("mute channel one", "unmute channel one"),
            
            // Identical strings
            ("set channel one to minus six", "set channel one to minus six")
        ]
        
        var latencies: [Double] = []
        
        for (str1, str2) in edgeCases {
            let startTime = Date()
            let _ = similarityEngine.calculateSimilarity(str1, str2)
            let latency = Date().timeIntervalSince(startTime) * 1000
            
            latencies.append(latency)
        }
        
        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0
        
        return IndividualTestResult(
            testName: "Edge Cases",
            averageLatencyMs: averageLatency,
            maxLatencyMs: maxLatency,
            testCount: edgeCases.count,
            passed: maxLatency < 50.0, // Edge cases should be fast
            details: "Empty, long, special chars"
        )
    }
    
    // MARK: - Helper Methods
    
    /// Create a mock ProcessedVoiceCommand for testing
    private func createMockCommand(_ text: String, confidence: Double) -> ProcessedVoiceCommand {
        let rcpCommand = RCPCommand(
            command: "mock command",
            description: text,
            confidence: confidence,
            category: .channelFader
        )
        
        return ProcessedVoiceCommand(
            originalText: text,
            rcpCommand: rcpCommand,
            confidence: confidence
        )
    }
    
    /// Print formatted test results
    private func printResults(_ results: PerformanceTestResults) {
        print("\n" + "=".repeating(60))
        print("🎭 SIMILARITY ENGINE PERFORMANCE TEST RESULTS")
        print("=".repeating(60))
        
        print("⏱️  Total Test Time: \(String(format: "%.2f", results.totalTestTimeMs))ms")
        print("📊 Average Latency: \(String(format: "%.2f", results.averageLatency))ms")
        print("✅ Overall Result: \(results.passed ? "PASSED" : "FAILED")")
        
        print("\n📋 Individual Test Results:")
        print("-".repeating(60))
        
        for test in results.individualTests {
            let status = test.passed ? "✅ PASS" : "❌ FAIL"
            print("\(status) \(test.testName)")
            print("    Avg: \(String(format: "%.2f", test.averageLatencyMs))ms | Max: \(String(format: "%.2f", test.maxLatencyMs))ms | Count: \(test.testCount)")
            if !test.details.isEmpty {
                print("    Details: \(test.details)")
            }
            print()
        }
        
        // Performance recommendations
        print("📈 Performance Analysis:")
        print("-".repeating(60))
        
        if results.averageLatency < 50.0 {
            print("🚀 EXCELLENT: Average latency well under 100ms requirement")
        } else if results.averageLatency < 100.0 {
            print("✅ GOOD: Average latency meets 100ms requirement")
        } else {
            print("⚠️  WARNING: Average latency exceeds 100ms requirement")
        }
        
        if results.individualTests.allSatisfy({ $0.maxLatencyMs < 200.0 }) {
            print("👍 No individual test exceeded 200ms")
        } else {
            print("⚠️  Some tests exceeded 200ms - consider optimization")
        }
        
        print("\n" + "=".repeating(60))
    }
}

// MARK: - Test Result Data Structures

/// Results from performance testing
struct PerformanceTestResults {
    let totalTestTimeMs: Double
    let individualTests: [IndividualTestResult]
    let passed: Bool
    let averageLatency: Double
}

/// Individual test result
struct IndividualTestResult {
    let testName: String
    let averageLatencyMs: Double
    let maxLatencyMs: Double
    let testCount: Int
    let passed: Bool
    let details: String
}

// MARK: - String Extension for Formatting

private extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}