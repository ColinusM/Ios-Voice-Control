import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

// MARK: - Cloud Sync Service

/// Premium cloud synchronization service for personal dictionaries and learning data
@MainActor
class CloudSyncService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current sync status
    @Published var syncStatus: CloudSyncStatus = .idle
    
    /// Last successful sync timestamp
    @Published var lastSyncTime: Date?
    
    /// Sync progress (0.0 - 1.0)
    @Published var syncProgress: Double = 0.0
    
    /// Whether premium sync is available
    @Published var isPremiumSyncAvailable: Bool = false
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Personal dictionary store
    private let dictionaryStore = PersonalDictionaryStore.shared
    
    /// Learning analytics
    private let analytics = LearningAnalytics.shared
    
    /// Authentication manager
    private weak var authManager: AuthenticationManager?
    
    /// Sync configuration
    private let syncConfig = CloudSyncConfiguration()
    
    /// Background sync timer
    private var syncTimer: Timer?
    
    // MARK: - Initialization
    
    init(authManager: AuthenticationManager? = nil) {
        self.authManager = authManager
        setupPremiumStatusMonitoring()
        setupAutoSync()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Manually trigger full sync
    /// - Returns: Result with sync summary or error
    func performFullSync() async -> Result<CloudSyncSummary, CloudSyncError> {
        guard isPremiumSyncAvailable else {
            return .failure(.premiumRequired("Cloud sync requires premium subscription"))
        }
        
        guard let authManager = authManager,
              let user = authManager.currentUser else {
            return .failure(.authenticationRequired("User must be signed in"))
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Upload personal dictionary
            syncProgress = 0.2
            let uploadResult = try await uploadPersonalDictionary(userId: user.uid)
            
            // Upload learning analytics
            syncProgress = 0.4
            let analyticsResult = try await uploadLearningAnalytics(userId: user.uid)
            
            // Download and merge remote data
            syncProgress = 0.6
            let downloadResult = try await downloadAndMergeRemoteData(userId: user.uid)
            
            // Cleanup old data
            syncProgress = 0.8
            try await cleanupOldCloudData(userId: user.uid)
            
            syncProgress = 1.0
            lastSyncTime = Date()
            syncStatus = .completed
            
            let summary = CloudSyncSummary(
                dictionaryEntriesUploaded: uploadResult.entriesCount,
                analyticsEventsUploaded: analyticsResult.entriesCount,
                remoteEntriesDownloaded: downloadResult.entriesCount,
                syncDuration: Date().timeIntervalSince(lastSyncTime ?? Date()),
                timestamp: Date()
            )
            
            print("☁️ CloudSyncService: Full sync completed - \(summary.description)")
            return .success(summary)
            
        } catch let error as CloudSyncError {
            syncStatus = .error(error.localizedDescription)
            syncProgress = 0.0
            print("❌ CloudSyncService: Sync failed - \(error.localizedDescription)")
            return .failure(error)
            
        } catch {
            let syncError = CloudSyncError.unknownError(error.localizedDescription)
            syncStatus = .error(syncError.localizedDescription)
            syncProgress = 0.0
            print("❌ CloudSyncService: Unknown sync error - \(error.localizedDescription)")
            return .failure(syncError)
        }
    }
    
    /// Upload personal dictionary to cloud
    /// - Parameter userId: User identifier
    /// - Returns: Upload result with count
    func uploadPersonalDictionary(userId: String) async throws -> CloudUploadResult {
        let entries = await dictionaryStore.getAllEntries()
        let userCollection = db.collection("users").document(userId).collection("dictionary")
        
        var uploadedCount = 0
        
        for entry in entries {
            let docData = try entry.toFirestoreData()
            let docRef = userCollection.document(entry.id.uuidString)
            
            try await docRef.setData(docData, merge: true)
            uploadedCount += 1
        }
        
        print("☁️ CloudSyncService: Uploaded \(uploadedCount) dictionary entries")
        return CloudUploadResult(entriesCount: uploadedCount, timestamp: Date())
    }
    
    /// Upload learning analytics to cloud
    /// - Parameter userId: User identifier  
    /// - Returns: Upload result with count
    func uploadLearningAnalytics(userId: String) async throws -> CloudUploadResult {
        let events = analytics.getRecentEvents(limit: syncConfig.maxAnalyticsEvents)
        let analyticsCollection = db.collection("users").document(userId).collection("analytics")
        
        var uploadedCount = 0
        
        for event in events {
            let docData = try event.toFirestoreData()
            let docRef = analyticsCollection.document(event.id.uuidString)
            
            try await docRef.setData(docData, merge: true)
            uploadedCount += 1
        }
        
        print("☁️ CloudSyncService: Uploaded \(uploadedCount) analytics events")
        return CloudUploadResult(entriesCount: uploadedCount, timestamp: Date())
    }
    
    /// Download and merge remote data
    /// - Parameter userId: User identifier
    /// - Returns: Download result with count
    func downloadAndMergeRemoteData(userId: String) async throws -> CloudDownloadResult {
        let userCollection = db.collection("users").document(userId).collection("dictionary")
        
        let snapshot = try await userCollection
            .whereField("timestamp", isGreaterThan: lastSyncTime ?? Date.distantPast)
            .getDocuments()
        
        var mergedCount = 0
        
        for document in snapshot.documents {
            do {
                let entry = try PersonalDictionaryEntry.fromFirestoreData(document.data())
                try await dictionaryStore.mergeEntry(entry)
                mergedCount += 1
            } catch {
                print("⚠️ CloudSyncService: Failed to merge entry \(document.documentID): \(error)")
            }
        }
        
        print("☁️ CloudSyncService: Downloaded and merged \(mergedCount) remote entries")
        return CloudDownloadResult(entriesCount: mergedCount, timestamp: Date())
    }
    
    /// Check cloud storage usage
    /// - Returns: Storage usage information
    func getStorageUsage() async -> Result<CloudStorageUsage, CloudSyncError> {
        guard let authManager = authManager,
              let user = authManager.currentUser else {
            return .failure(.authenticationRequired("User must be signed in"))
        }
        
        do {
            // Get dictionary entries count
            let dictionarySnapshot = try await db.collection("users")
                .document(user.uid)
                .collection("dictionary")
                .getDocuments()
            
            // Get analytics events count
            let analyticsSnapshot = try await db.collection("users")
                .document(user.uid)
                .collection("analytics")
                .getDocuments()
            
            let usage = CloudStorageUsage(
                dictionaryEntries: dictionarySnapshot.count,
                analyticsEvents: analyticsSnapshot.count,
                estimatedSizeBytes: calculateEstimatedSize(
                    dictionaryCount: dictionarySnapshot.count,
                    analyticsCount: analyticsSnapshot.count
                ),
                lastUpdated: Date()
            )
            
            return .success(usage)
            
        } catch {
            return .failure(.networkError("Failed to retrieve storage usage: \(error.localizedDescription)"))
        }
    }
    
    /// Clear all cloud data for user
    /// - Returns: Result with deletion count
    func clearCloudData() async -> Result<Int, CloudSyncError> {
        guard let authManager = authManager,
              let user = authManager.currentUser else {
            return .failure(.authenticationRequired("User must be signed in"))
        }
        
        do {
            var deletedCount = 0
            
            // Delete dictionary entries
            let dictionarySnapshot = try await db.collection("users")
                .document(user.uid)
                .collection("dictionary")
                .getDocuments()
            
            for document in dictionarySnapshot.documents {
                try await document.reference.delete()
                deletedCount += 1
            }
            
            // Delete analytics events
            let analyticsSnapshot = try await db.collection("users")
                .document(user.uid)
                .collection("analytics")
                .getDocuments()
            
            for document in analyticsSnapshot.documents {
                try await document.reference.delete()
                deletedCount += 1
            }
            
            print("☁️ CloudSyncService: Deleted \(deletedCount) cloud documents")
            return .success(deletedCount)
            
        } catch {
            return .failure(.networkError("Failed to clear cloud data: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Private Implementation
    
    /// Setup premium status monitoring
    private func setupPremiumStatusMonitoring() {
        // Monitor authentication state changes
        authManager?.$currentUser
            .sink { [weak self] (user: User?) in
                Task { @MainActor in
                    self?.updatePremiumStatus()
                }
            }
            .store(in: &cancellables)
        
        // Monitor premium subscription status would need to be done differently
        // since isPremiumUser is a computed property, not @Published
    }
    
    /// Setup automatic sync
    private func setupAutoSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncConfig.autoSyncIntervalMinutes * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isPremiumSyncAvailable == true && self?.syncStatus == .idle {
                    let _ = await self?.performFullSync()
                }
            }
        }
    }
    
    /// Update premium status
    @MainActor
    private func updatePremiumStatus() {
        Task { @MainActor in
            isPremiumSyncAvailable = (authManager?.isPremiumUser == true) && authManager?.currentUser != nil
        }
    }
    
    /// Cleanup old cloud data beyond retention period
    /// - Parameter userId: User identifier
    private func cleanupOldCloudData(userId: String) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -syncConfig.dataRetentionDays, to: Date()) ?? Date.distantPast
        
        // Cleanup old analytics events
        let analyticsQuery = db.collection("users")
            .document(userId)
            .collection("analytics")
            .whereField("timestamp", isLessThan: cutoffDate)
        
        let snapshot = try await analyticsQuery.getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        
        if !snapshot.isEmpty {
            print("☁️ CloudSyncService: Cleaned up \(snapshot.count) old analytics events")
        }
    }
    
    /// Calculate estimated storage size
    /// - Parameters:
    ///   - dictionaryCount: Number of dictionary entries
    ///   - analyticsCount: Number of analytics events
    /// - Returns: Estimated size in bytes
    private func calculateEstimatedSize(dictionaryCount: Int, analyticsCount: Int) -> Int {
        let avgDictionaryEntrySize = 150 // bytes
        let avgAnalyticsEventSize = 100 // bytes
        
        return (dictionaryCount * avgDictionaryEntrySize) + (analyticsCount * avgAnalyticsEventSize)
    }
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Cloud Sync Status

/// Current status of cloud synchronization
enum CloudSyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case error(String)
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Sync completed"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
}

// MARK: - Cloud Sync Errors

/// Errors that can occur during cloud synchronization
enum CloudSyncError: LocalizedError, Equatable {
    case premiumRequired(String)
    case authenticationRequired(String)
    case networkError(String)
    case quotaExceeded(String)
    case dataCorruption(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .premiumRequired(let message):
            return "Premium Required: \(message)"
        case .authenticationRequired(let message):
            return "Authentication Required: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .quotaExceeded(let message):
            return "Quota Exceeded: \(message)"
        case .dataCorruption(let message):
            return "Data Corruption: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .premiumRequired:
            return "Upgrade to premium to enable cloud sync"
        case .authenticationRequired:
            return "Sign in to sync your data"
        case .networkError:
            return "Check your internet connection and try again"
        case .quotaExceeded:
            return "Clear old data or upgrade your storage quota"
        case .dataCorruption:
            return "Clear cloud data and perform a fresh sync"
        case .unknownError:
            return "Try again or contact support"
        }
    }
}

// MARK: - Supporting Data Structures

/// Summary of sync operation
struct CloudSyncSummary {
    let dictionaryEntriesUploaded: Int
    let analyticsEventsUploaded: Int
    let remoteEntriesDownloaded: Int
    let syncDuration: TimeInterval
    let timestamp: Date
    
    var description: String {
        return """
        Sync Summary:
        • Uploaded \(dictionaryEntriesUploaded) dictionary entries
        • Uploaded \(analyticsEventsUploaded) analytics events
        • Downloaded \(remoteEntriesDownloaded) remote entries
        • Duration: \(String(format: "%.2f", syncDuration))s
        """
    }
}

/// Result of upload operation
struct CloudUploadResult {
    let entriesCount: Int
    let timestamp: Date
}

/// Result of download operation
struct CloudDownloadResult {
    let entriesCount: Int
    let timestamp: Date
}

/// Cloud storage usage information
struct CloudStorageUsage {
    let dictionaryEntries: Int
    let analyticsEvents: Int
    let estimatedSizeBytes: Int
    let lastUpdated: Date
    
    var estimatedSizeMB: Double {
        return Double(estimatedSizeBytes) / (1024 * 1024)
    }
    
    var description: String {
        return """
        Cloud Storage Usage:
        • Dictionary entries: \(dictionaryEntries)
        • Analytics events: \(analyticsEvents)
        • Estimated size: \(String(format: "%.2f", estimatedSizeMB)) MB
        • Last updated: \(DateFormatter.shortFormat.string(from: lastUpdated))
        """
    }
}

/// Cloud sync configuration
struct CloudSyncConfiguration {
    /// Auto-sync interval in minutes
    let autoSyncIntervalMinutes: Double = 30
    
    /// Maximum analytics events to sync
    let maxAnalyticsEvents: Int = 1000
    
    /// Data retention period in days
    let dataRetentionDays: Int = 90
    
    /// Maximum upload batch size
    let maxBatchSize: Int = 100
}

// MARK: - Firestore Extensions

extension PersonalDictionaryEntry {
    /// Convert to Firestore-compatible data
    func toFirestoreData() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let dictionary = json as? [String: Any] else {
            throw CloudSyncError.dataCorruption("Failed to convert entry to Firestore format")
        }
        
        return dictionary
    }
    
    /// Create from Firestore data
    static func fromFirestoreData(_ data: [String: Any]) throws -> PersonalDictionaryEntry {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(PersonalDictionaryEntry.self, from: jsonData)
    }
}

extension LearningEvent {
    /// Convert to Firestore-compatible data
    func toFirestoreData() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let dictionary = json as? [String: Any] else {
            throw CloudSyncError.dataCorruption("Failed to convert event to Firestore format")
        }
        
        return dictionary
    }
    
    /// Create from Firestore data
    static func fromFirestoreData(_ data: [String: Any]) throws -> LearningEvent {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(LearningEvent.self, from: jsonData)
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let shortFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Singleton Access

extension CloudSyncService {
    /// Shared cloud sync service instance
    static let shared = CloudSyncService()
    
    /// Create shared instance with authentication manager
    static func createShared(with authManager: AuthenticationManager) -> CloudSyncService {
        return CloudSyncService(authManager: authManager)
    }
}