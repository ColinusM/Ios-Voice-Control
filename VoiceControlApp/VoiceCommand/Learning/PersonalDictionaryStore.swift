import Foundation

/// Thread-safe personal dictionary store using UserDefaults with separate keys
/// Avoids 1MB limit by storing each entry individually
actor PersonalDictionaryStore {
    
    // MARK: - Configuration
    
    /// Key prefix for all dictionary entries
    private let keyPrefix = "voice_learning_"
    
    /// UserDefaults instance
    private let userDefaults = UserDefaults.standard
    
    /// Maximum entries to prevent unlimited growth
    private let maxEntries = 1000
    
    /// Cache for frequently accessed entries
    private var entryCache: [String: PersonalDictionaryEntry] = [:]
    
    /// Cache size limit
    private let maxCacheSize = 100
    
    // MARK: - Public Interface
    
    /// Add a new dictionary entry
    /// - Parameter entry: The entry to add
    func addEntry(_ entry: PersonalDictionaryEntry) async throws {
        let key = generateKey(for: entry.originalCommand)
        
        // Check if entry already exists and update usage
        if var existingEntry = await getEntry(for: entry.originalCommand) {
            existingEntry = PersonalDictionaryEntry(
                id: existingEntry.id,
                originalCommand: existingEntry.originalCommand,
                correctedCommand: entry.correctedCommand, // Use new correction
                confidence: max(existingEntry.confidence, entry.confidence),
                createdAt: existingEntry.createdAt,
                useCount: existingEntry.useCount + 1,
                lastUsed: Date(),
                wasConsoleConnected: entry.wasConsoleConnected || existingEntry.wasConsoleConnected,
                userResponse: entry.userResponse ?? existingEntry.userResponse
            )
            
            try await saveEntry(existingEntry, for: key)
            print("📚 Updated existing dictionary entry: '\(entry.originalCommand)' -> '\(entry.correctedCommand)'")
        } else {
            // Add new entry
            try await saveEntry(entry, for: key)
            print("📚 Added new dictionary entry: '\(entry.originalCommand)' -> '\(entry.correctedCommand)'")
        }
        
        // Cleanup old entries if we exceed maximum
        await cleanupOldEntriesIfNeeded()
    }
    
    /// Get entry for a specific original command
    /// - Parameter originalCommand: The original command text
    /// - Returns: Dictionary entry if found
    func getEntry(for originalCommand: String) async -> PersonalDictionaryEntry? {
        let key = generateKey(for: originalCommand)
        
        // Check cache first
        if let cachedEntry = entryCache[key] {
            return cachedEntry
        }
        
        // Load from UserDefaults
        guard let data = userDefaults.data(forKey: key),
              let entry = try? JSONDecoder().decode(PersonalDictionaryEntry.self, from: data) else {
            return nil
        }
        
        // Add to cache
        entryCache[key] = entry
        manageCacheSize()
        
        return entry
    }
    
    /// Find similar entries for a given command
    /// - Parameter command: The command to find similar entries for
    /// - Returns: Array of similar dictionary entries
    func findSimilarEntries(for command: String) async -> [PersonalDictionaryEntry] {
        let allEntries = await getAllEntries()
        let similarityEngine = SimilarityEngine()
        var similarEntries: [PersonalDictionaryEntry] = []
        
        for entry in allEntries {
            if similarityEngine.areSimilar(command, entry.originalCommand) {
                similarEntries.append(entry)
            }
        }
        
        // Sort by confidence and usage
        return similarEntries.sorted { entry1, entry2 in
            let score1 = entry1.confidence * Double(entry1.useCount)
            let score2 = entry2.confidence * Double(entry2.useCount)
            return score1 > score2
        }
    }
    
    /// Get all dictionary entries
    /// - Returns: Array of all entries
    func getAllEntries() async -> [PersonalDictionaryEntry] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
        
        var entries: [PersonalDictionaryEntry] = []
        
        for key in allKeys {
            if let data = userDefaults.data(forKey: key),
               let entry = try? JSONDecoder().decode(PersonalDictionaryEntry.self, from: data) {
                entries.append(entry)
            }
        }
        
        return entries.sorted { $0.lastUsed > $1.lastUsed }
    }
    
    /// Get entries filtered by console connection status
    /// - Parameter consoleConnectedOnly: Whether to return only console-connected entries
    /// - Returns: Filtered array of entries
    func getEntries(consoleConnectedOnly: Bool) async -> [PersonalDictionaryEntry] {
        let allEntries = await getAllEntries()
        
        if consoleConnectedOnly {
            return allEntries.filter { $0.wasConsoleConnected }
        } else {
            return allEntries
        }
    }
    
    /// Update usage statistics for an entry
    /// - Parameter originalCommand: The original command to update
    func incrementUsage(for originalCommand: String) async {
        guard var entry = await getEntry(for: originalCommand) else { return }
        
        let updatedEntry = PersonalDictionaryEntry(
            id: entry.id,
            originalCommand: entry.originalCommand,
            correctedCommand: entry.correctedCommand,
            confidence: entry.confidence,
            createdAt: entry.createdAt,
            useCount: entry.useCount + 1,
            lastUsed: Date(),
            wasConsoleConnected: entry.wasConsoleConnected,
            userResponse: entry.userResponse
        )
        
        let key = generateKey(for: originalCommand)
        try? await saveEntry(updatedEntry, for: key)
    }
    
    /// Remove an entry from the dictionary
    /// - Parameter originalCommand: The original command to remove
    func removeEntry(for originalCommand: String) async {
        let key = generateKey(for: originalCommand)
        userDefaults.removeObject(forKey: key)
        entryCache.removeValue(forKey: key)
        
        print("🗑️ Removed dictionary entry: '\(originalCommand)'")
    }
    
    /// Clear all dictionary entries
    func clearAll() async {
        let allKeys = userDefaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
        
        for key in allKeys {
            userDefaults.removeObject(forKey: key)
        }
        
        entryCache.removeAll()
        print("🗑️ Cleared all dictionary entries")
    }
    
    /// Get dictionary statistics
    /// - Returns: Statistics about the dictionary
    func getStatistics() async -> DictionaryStatistics {
        let allEntries = await getAllEntries()
        let consoleEntries = allEntries.filter { $0.wasConsoleConnected }
        let acceptedEntries = allEntries.filter { $0.userResponse == .accepted }
        let rejectedEntries = allEntries.filter { $0.userResponse == .rejected }
        
        let totalUsage = allEntries.reduce(0) { $0 + $1.useCount }
        let averageConfidence = allEntries.isEmpty ? 0.0 : 
            allEntries.reduce(0.0) { $0 + $1.confidence } / Double(allEntries.count)
        
        return DictionaryStatistics(
            totalEntries: allEntries.count,
            consoleConnectedEntries: consoleEntries.count,
            acceptedEntries: acceptedEntries.count,
            rejectedEntries: rejectedEntries.count,
            totalUsage: totalUsage,
            averageConfidence: averageConfidence,
            oldestEntry: allEntries.min(by: { $0.createdAt < $1.createdAt })?.createdAt,
            newestEntry: allEntries.max(by: { $0.createdAt < $1.createdAt })?.createdAt
        )
    }
    
    /// Merge a dictionary entry (used by CloudSyncService)
    /// - Parameter entry: The entry to merge
    func mergeEntry(_ entry: PersonalDictionaryEntry) async throws {
        if let existingEntry = await getEntry(for: entry.originalCommand) {
            // Merge with existing entry using mergeData strategy
            let mergedEntry = try await resolveConflict(existing: existingEntry, incoming: entry, strategy: .mergeData)
            let key = generateKey(for: entry.originalCommand)
            try await saveEntry(mergedEntry, for: key)
        } else {
            // Add as new entry
            try await addEntry(entry)
        }
    }
    
    /// Export dictionary data for cloud sync or backup
    /// - Returns: Exportable dictionary data
    func exportData() async -> DictionaryExportData {
        let allEntries = await getAllEntries()
        return DictionaryExportData(
            entries: allEntries,
            exportDate: Date(),
            version: "1.0"
        )
    }
    
    /// Import dictionary data from cloud sync or backup
    /// - Parameter data: Dictionary data to import
    /// - Parameter mergeStrategy: How to handle conflicts
    func importData(_ data: DictionaryExportData, mergeStrategy: MergeStrategy = .keepNewer) async throws {
        for entry in data.entries {
            if let existingEntry = await getEntry(for: entry.originalCommand) {
                // Handle merge conflict
                let entryToKeep = try await resolveConflict(existing: existingEntry, incoming: entry, strategy: mergeStrategy)
                let key = generateKey(for: entry.originalCommand)
                try await saveEntry(entryToKeep, for: key)
            } else {
                // Add new entry
                try await addEntry(entry)
            }
        }
        
        print("📥 Imported \(data.entries.count) dictionary entries")
    }
    
    // MARK: - Private Implementation
    
    /// Generate UserDefaults key for an original command
    /// - Parameter originalCommand: The original command text
    /// - Returns: Unique key for storage
    private func generateKey(for originalCommand: String) -> String {
        let hash = originalCommand.lowercased().hashValue
        return "\(keyPrefix)\(abs(hash))"
    }
    
    /// Save entry to UserDefaults
    /// - Parameters:
    ///   - entry: Entry to save
    ///   - key: Storage key
    private func saveEntry(_ entry: PersonalDictionaryEntry, for key: String) async throws {
        do {
            let data = try JSONEncoder().encode(entry)
            userDefaults.set(data, forKey: key)
            
            // Update cache
            entryCache[key] = entry
            manageCacheSize()
            
        } catch {
            throw PersonalDictionaryError.encodingFailed(error.localizedDescription)
        }
    }
    
    /// Manage cache size to prevent memory growth
    private func manageCacheSize() {
        if entryCache.count > maxCacheSize {
            // Remove oldest entries (simple LRU approximation)
            let keysToRemove = Array(entryCache.keys.prefix(entryCache.count - maxCacheSize + 10))
            for key in keysToRemove {
                entryCache.removeValue(forKey: key)
            }
        }
    }
    
    /// Clean up old entries if we exceed maximum count
    private func cleanupOldEntriesIfNeeded() async {
        let allEntries = await getAllEntries()
        
        if allEntries.count > maxEntries {
            // Sort by usage and age, remove least valuable entries
            let sortedEntries = allEntries.sorted { entry1, entry2 in
                let score1 = Double(entry1.useCount) * entry1.confidence * (1.0 / max(1.0, entry1.createdAt.timeIntervalSinceNow / -86400))
                let score2 = Double(entry2.useCount) * entry2.confidence * (1.0 / max(1.0, entry2.createdAt.timeIntervalSinceNow / -86400))
                return score1 > score2
            }
            
            let entriesToRemove = sortedEntries.suffix(allEntries.count - maxEntries + 50) // Remove extra for buffer
            
            for entry in entriesToRemove {
                await removeEntry(for: entry.originalCommand)
            }
            
            print("🧹 Cleaned up \(entriesToRemove.count) old dictionary entries")
        }
    }
    
    /// Resolve conflict between existing and incoming entries
    /// - Parameters:
    ///   - existing: Existing entry
    ///   - incoming: Incoming entry
    ///   - strategy: Merge strategy
    /// - Returns: Resolved entry
    private func resolveConflict(existing: PersonalDictionaryEntry, incoming: PersonalDictionaryEntry, strategy: MergeStrategy) async throws -> PersonalDictionaryEntry {
        switch strategy {
        case .keepExisting:
            return existing
            
        case .keepIncoming:
            return incoming
            
        case .keepNewer:
            return existing.lastUsed > incoming.lastUsed ? existing : incoming
            
        case .mergeData:
            return PersonalDictionaryEntry(
                id: existing.id,
                originalCommand: existing.originalCommand,
                correctedCommand: incoming.correctedCommand, // Use newer correction
                confidence: max(existing.confidence, incoming.confidence),
                createdAt: existing.createdAt, // Keep original creation date
                useCount: existing.useCount + incoming.useCount,
                lastUsed: max(existing.lastUsed, incoming.lastUsed),
                wasConsoleConnected: existing.wasConsoleConnected || incoming.wasConsoleConnected,
                userResponse: incoming.userResponse ?? existing.userResponse
            )
        }
    }
}

// MARK: - Supporting Data Structures

/// Personal dictionary entry structure
struct PersonalDictionaryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let originalCommand: String
    let correctedCommand: String
    let confidence: Double
    let createdAt: Date
    let useCount: Int
    let lastUsed: Date
    let wasConsoleConnected: Bool
    let userResponse: LearningResponse?
    
    init(
        id: UUID = UUID(),
        originalCommand: String,
        correctedCommand: String,
        confidence: Double,
        createdAt: Date = Date(),
        useCount: Int = 1,
        lastUsed: Date = Date(),
        wasConsoleConnected: Bool,
        userResponse: LearningResponse? = nil
    ) {
        self.id = id
        self.originalCommand = originalCommand
        self.correctedCommand = correctedCommand
        self.confidence = max(0.0, min(1.0, confidence))
        self.createdAt = createdAt
        self.useCount = max(1, useCount)
        self.lastUsed = lastUsed
        self.wasConsoleConnected = wasConsoleConnected
        self.userResponse = userResponse
    }
    
    /// Formatted description for debugging
    var description: String {
        return "'\(originalCommand)' → '\(correctedCommand)' (confidence: \(String(format: "%.2f", confidence)), used: \(useCount)x)"
    }
    
    /// Data for Firebase sync
    var firebaseData: [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "originalCommand": originalCommand,
            "correctedCommand": correctedCommand,
            "confidence": confidence,
            "createdAt": createdAt.timeIntervalSince1970,
            "useCount": useCount,
            "lastUsed": lastUsed.timeIntervalSince1970,
            "wasConsoleConnected": wasConsoleConnected
        ]
        
        if let response = userResponse {
            data["userResponse"] = response.rawValue
        }
        
        return data
    }
}

/// User response to learning prompt
enum LearningResponse: String, Codable, CaseIterable {
    case accepted = "accepted"
    case rejected = "rejected"
    case ignored = "ignored"
    
    var emoji: String {
        switch self {
        case .accepted: return "✅"
        case .rejected: return "❌"
        case .ignored: return "⏭️"
        }
    }
}

/// Dictionary statistics
struct DictionaryStatistics {
    let totalEntries: Int
    let consoleConnectedEntries: Int
    let acceptedEntries: Int
    let rejectedEntries: Int
    let totalUsage: Int
    let averageConfidence: Double
    let oldestEntry: Date?
    let newestEntry: Date?
    
    var description: String {
        return """
        Personal Dictionary Statistics:
        - Total entries: \(totalEntries)
        - Console-connected: \(consoleConnectedEntries)
        - User accepted: \(acceptedEntries)
        - User rejected: \(rejectedEntries)
        - Total usage: \(totalUsage)
        - Average confidence: \(String(format: "%.2f", averageConfidence))
        - Age range: \(ageRangeDescription)
        """
    }
    
    private var ageRangeDescription: String {
        guard let oldest = oldestEntry, let newest = newestEntry else {
            return "No entries"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: oldest)) - \(formatter.string(from: newest))"
    }
}

/// Data structure for export/import
struct DictionaryExportData: Codable {
    let entries: [PersonalDictionaryEntry]
    let exportDate: Date
    let version: String
}

/// Merge strategy for import conflicts
enum MergeStrategy {
    case keepExisting
    case keepIncoming
    case keepNewer
    case mergeData
}

/// Dictionary-specific errors
enum PersonalDictionaryError: LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case storageQuotaExceeded
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let details):
            return "Failed to encode dictionary entry: \(details)"
        case .decodingFailed(let details):
            return "Failed to decode dictionary entry: \(details)"
        case .storageQuotaExceeded:
            return "Dictionary storage quota exceeded"
        case .invalidData(let details):
            return "Invalid dictionary data: \(details)"
        }
    }
}

// MARK: - Singleton Access

extension PersonalDictionaryStore {
    /// Shared instance for global access
    static let shared = PersonalDictionaryStore()
}