#!/usr/bin/env swift

import Foundation

// Simple performance test for SimilarityEngine
// Tests the core Levenshtein distance algorithm performance

/// Optimized Levenshtein distance calculation (copied from SimilarityEngine)
func calculateLevenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let a = Array(s1)
    let b = Array(s2)
    let m = a.count
    let n = b.count
    
    // Optimization: return early for identical strings
    if s1 == s2 { return 0 }
    
    // Optimization: return early for empty strings
    if m == 0 { return n }
    if n == 0 { return m }
    
    // Use single array optimization for better memory usage
    var previousRow = Array(0...n)
    var currentRow = Array(repeating: 0, count: n + 1)
    
    for i in 1...m {
        currentRow[0] = i
        
        for j in 1...n {
            let insertionCost = previousRow[j] + 1
            let deletionCost = currentRow[j - 1] + 1
            let substitutionCost = previousRow[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)
            
            currentRow[j] = min(insertionCost, deletionCost, substitutionCost)
        }
        
        // Swap arrays
        (previousRow, currentRow) = (currentRow, previousRow)
    }
    
    return previousRow[n]
}

/// Calculate similarity score (0.0 to 1.0)
func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
    let distance = calculateLevenshteinDistance(str1, str2)
    let maxLength = max(str1.count, str2.count)
    
    return maxLength == 0 ? 1.0 : 1.0 - Double(distance) / Double(maxLength)
}

/// Run performance tests
func runPerformanceTests() {
    print("🚀 Testing SimilarityEngine Performance...")
    
    let testCases = [
        ("set channel one to minus six", "set channel 1 to -6 db"),
        ("mute the kick drum", "mute kick"),
        ("add reverb to vocals", "set vocal reverb on"),
        ("turn up the bass guitar", "increase bass level"),
        ("recall scene three", "load scene 3"),
        ("solo snare drum", "snare solo"),
        ("pan guitar left", "guitar pan left"),
        ("cut high frequencies on bass", "bass high cut"),
        ("increase vocal level", "vocal level up"),
        ("add delay to guitar", "guitar delay on")
    ]
    
    // Test 1: Single comparisons
    print("\n📊 Test 1: Single Similarity Comparisons")
    var singleLatencies: [Double] = []
    
    for (original, corrected) in testCases {
        let startTime = CFAbsoluteTimeGetCurrent()
        let similarity = calculateSimilarity(original, corrected)
        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        singleLatencies.append(latency)
        print("  '\(original)' vs '\(corrected)': \(String(format: "%.3f", similarity)) similarity, \(String(format: "%.2f", latency))ms")
    }
    
    let avgSingle = singleLatencies.reduce(0, +) / Double(singleLatencies.count)
    let maxSingle = singleLatencies.max() ?? 0
    print("  Average: \(String(format: "%.2f", avgSingle))ms, Max: \(String(format: "%.2f", maxSingle))ms")
    
    // Test 2: Batch processing (realistic scenario)
    print("\n📊 Test 2: Batch Similarity Detection (1 vs 5 commands)")
    
    let successfulCommand = "set channel one to minus six db"
    let recentFailures = [
        "set channel one to six",
        "channel one minus six", 
        "set one to minus six db",
        "set channel to minus six",
        "channel one to six db"
    ]
    
    var batchLatencies: [Double] = []
    
    // Run 50 iterations for reliable data
    for _ in 0..<50 {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate finding similar commands
        var similarities: [(String, Double)] = []
        for failure in recentFailures {
            let similarity = calculateSimilarity(successfulCommand, failure)
            if similarity > 0.6 { // Similarity threshold
                similarities.append((failure, similarity))
            }
        }
        
        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        batchLatencies.append(latency)
    }
    
    let avgBatch = batchLatencies.reduce(0, +) / Double(batchLatencies.count)
    let maxBatch = batchLatencies.max() ?? 0
    print("  Average: \(String(format: "%.2f", avgBatch))ms, Max: \(String(format: "%.2f", maxBatch))ms")
    
    // Test 3: Large dataset (10 vs 20 commands)
    print("\n📊 Test 3: Large Dataset Similarity (10 vs 20 commands)")
    
    let manyFailures = Array(0..<20).map { "command variant number \($0) with some text" }
    let testCommand = "set channel one to minus six db"
    
    var largeLatencies: [Double] = []
    
    for _ in 0..<20 {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for failure in manyFailures {
            let _ = calculateSimilarity(testCommand, failure)
        }
        
        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        largeLatencies.append(latency)
    }
    
    let avgLarge = largeLatencies.reduce(0, +) / Double(largeLatencies.count)
    let maxLarge = largeLatencies.max() ?? 0
    print("  Average: \(String(format: "%.2f", avgLarge))ms, Max: \(String(format: "%.2f", maxLarge))ms")
    
    // Results summary
    print("\n" + String(repeating: "=", count: 60))
    print("📈 PERFORMANCE TEST RESULTS")
    print(String(repeating: "=", count: 60))
    
    let overallAvg = (avgSingle + avgBatch + avgLarge) / 3.0
    print("Overall Average Latency: \(String(format: "%.2f", overallAvg))ms")
    
    let requirement = 100.0
    if overallAvg < requirement {
        print("✅ PASSED: Performance meets <\(Int(requirement))ms requirement")
    } else {
        print("❌ FAILED: Performance exceeds \(Int(requirement))ms requirement")
    }
    
    print("\nDetailed Results:")
    print("• Single comparisons: \(String(format: "%.2f", avgSingle))ms avg")
    print("• Batch processing: \(String(format: "%.2f", avgBatch))ms avg") 
    print("• Large dataset: \(String(format: "%.2f", avgLarge))ms avg")
    
    if maxBatch < requirement && maxLarge < requirement {
        print("\n🚀 EXCELLENT: All scenarios well under \(Int(requirement))ms")
    } else if avgBatch < requirement && avgLarge < requirement {
        print("\n👍 GOOD: Average performance meets requirements")
    } else {
        print("\n⚠️  WARNING: Performance optimization needed")
    }
}

// Run the tests
runPerformanceTests()