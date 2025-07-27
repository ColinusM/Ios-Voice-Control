import Foundation
import SwiftUI
import StoreKit

// MARK: - Subscription State Manager with ObservableObject Pattern

class SubscriptionManager: ObservableObject {
    @Published var subscriptionState: SubscriptionState = .unknown
    @Published var availablePlans: [SubscriptionPlan] = []
    @Published var currentSubscription: StoreKitSubscriptionStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storeKitService = StoreKitService()
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        // PATTERN: Mirror AuthenticationManager initialization
        updateListenerTask = listenForTransactionUpdates()
        Task {
            await loadAvailableProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    @MainActor
    func loadAvailableProducts() async {
        #if DEBUG
        print("🔵 SubscriptionManager: Loading available products")
        #endif
        
        isLoading = true
        errorMessage = nil
        
        let result = await StoreKitService.loadProducts()
        
        switch result {
        case .success(let products):
            // Map StoreKit products to SubscriptionPlans
            var updatedPlans: [SubscriptionPlan] = []
            
            for product in products {
                if let plan = SubscriptionPlan.plan(for: product.id) {
                    let updatedPlan = plan.withStoreKitProduct(product)
                    updatedPlans.append(updatedPlan)
                }
            }
            
            availablePlans = updatedPlans
            
            #if DEBUG
            print("✅ SubscriptionManager: Loaded \(availablePlans.count) subscription plans")
            #endif
            
        case .failure(let subscriptionError):
            errorMessage = subscriptionError.localizedDescription
            subscriptionState = .error(subscriptionError)
            
            #if DEBUG
            print("❌ SubscriptionManager: Failed to load products - \(subscriptionError.localizedDescription)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status Management
    
    @MainActor
    func checkSubscriptionStatus() async {
        #if DEBUG
        print("🔵 SubscriptionManager: Checking subscription status")
        #endif
        
        // PATTERN: Mirror checkPersistedSession from AuthenticationManager
        subscriptionState = .loading
        
        let statusResult = await StoreKitService.checkSubscriptionStatus()
        
        switch statusResult {
        case .success(let status):
            currentSubscription = status
            
            if status.isActive {
                subscriptionState = .premium(expirationDate: status.expirationDate)
                
                #if DEBUG
                print("✅ SubscriptionManager: Active premium subscription found")
                if let productId = status.productId {
                    print("   Product ID: \(productId)")
                }
                if let expiration = status.expirationDate {
                    print("   Expires: \(expiration)")
                }
                #endif
            } else {
                // No active subscription - check guest usage
                if let authManager = getCurrentAuthManager() {
                    if let guestUser = authManager.guestUser {
                        subscriptionState = .free(remainingMinutes: guestUser.remainingFreeMinutes)
                        
                        #if DEBUG
                        print("ℹ️ SubscriptionManager: Guest user with \(guestUser.remainingFreeMinutes) minutes remaining")
                        #endif
                    } else {
                        subscriptionState = .free(remainingMinutes: 60) // Default 1 hour free
                        
                        #if DEBUG
                        print("ℹ️ SubscriptionManager: New user with 60 minutes free")
                        #endif
                    }
                } else {
                    subscriptionState = .free(remainingMinutes: 60) // Default 1 hour free
                }
            }
            
        case .failure(let subscriptionError):
            subscriptionState = .error(subscriptionError)
            errorMessage = subscriptionError.localizedDescription
            
            #if DEBUG
            print("❌ SubscriptionManager: Failed to check subscription status - \(subscriptionError.localizedDescription)")
            #endif
        }
    }
    
    // MARK: - Purchase Methods
    
    @MainActor
    func purchase(_ plan: SubscriptionPlan) async {
        #if DEBUG
        print("🔵 SubscriptionManager: Initiating purchase for \(plan.displayName)")
        #endif
        
        guard let product = plan.storeKitProduct else {
            let error = SubscriptionError.productNotFound
            subscriptionState = .error(error)
            errorMessage = error.localizedDescription
            return
        }
        
        isLoading = true
        errorMessage = nil
        subscriptionState = .loading
        
        let result = await StoreKitService.purchase(product)
        
        switch result {
        case .success(let purchaseResult):
            #if DEBUG
            print("✅ SubscriptionManager: Purchase successful")
            print("   Transaction ID: \(purchaseResult.transactionId)")
            #endif
            
            // Update subscription status after successful purchase
            await checkSubscriptionStatus()
            
        case .failure(let subscriptionError):
            subscriptionState = .error(subscriptionError)
            errorMessage = subscriptionError.localizedDescription
            
            #if DEBUG
            print("❌ SubscriptionManager: Purchase failed - \(subscriptionError.localizedDescription)")
            #endif
        }
        
        isLoading = false
    }
    
    @MainActor
    func restorePurchases() async {
        #if DEBUG
        print("🔵 SubscriptionManager: Restoring purchases")
        #endif
        
        isLoading = true
        errorMessage = nil
        
        let result = await StoreKitService.restorePurchases()
        
        switch result {
        case .success(let restoredProducts):
            #if DEBUG
            print("✅ SubscriptionManager: Restored \(restoredProducts.count) purchases")
            #endif
            
            // Check subscription status after restore
            await checkSubscriptionStatus()
            
        case .failure(let subscriptionError):
            errorMessage = subscriptionError.localizedDescription
            
            #if DEBUG
            print("❌ SubscriptionManager: Restore failed - \(subscriptionError.localizedDescription)")
            #endif
        }
        
        isLoading = false
    }
    
    // MARK: - API Access Control
    
    /// Whether the user can access the AssemblyAI API ($0.17/hour)
    /// This is the critical method that gates expensive API calls
    var canAccessAPI: Bool {
        return subscriptionState.canAccessAPI
    }
    
    /// Updates API usage for guest users (in minutes)
    /// This should be called after each AssemblyAI API session
    @MainActor
    func updateAPIUsage(minutesUsed: Int) async {
        #if DEBUG
        print("🔵 SubscriptionManager: Updating API usage by \(minutesUsed) minutes")
        #endif
        
        // Only track usage for free tier users
        if case .free(let currentMinutes) = subscriptionState {
            let newRemainingMinutes = max(0, currentMinutes - minutesUsed)
            subscriptionState = .free(remainingMinutes: newRemainingMinutes)
            
            #if DEBUG
            print("   Remaining minutes: \(newRemainingMinutes)/60")
            #endif
            
            // Update guest user if available
            if let authManager = getCurrentAuthManager() {
                Task { @MainActor in
                    await authManager.updateGuestUsage(minutesUsed: minutesUsed)
                }
            }
            
            // Check if user should be shown upgrade prompts
            if newRemainingMinutes <= 15 { // 25% remaining
                #if DEBUG
                print("⚠️ SubscriptionManager: User approaching usage limits")
                #endif
            }
        }
    }
    
    // MARK: - Transaction Updates Listener
    
    /// Listen for transaction updates from StoreKit
    /// PATTERN: Mirror AuthenticationManager listener setup
    @Sendable
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // Use StoreKitService verification method
                    let transaction = try self.checkVerified(result)
                    
                    #if DEBUG
                    print("🔄 SubscriptionManager: Transaction update received")
                    print("   Product ID: \(transaction.productID)")
                    print("   Transaction ID: \(transaction.id)")
                    #endif
                    
                    // Update subscription status on main actor
                    Task { @MainActor in
                        await self.checkSubscriptionStatus()
                    }
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                } catch {
                    #if DEBUG
                    print("❌ SubscriptionManager: Failed to handle transaction update - \(error)")
                    #endif
                }
            }
        }
    }
    
    /// Verifies a transaction result (mirrors StoreKitService method)
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            #if DEBUG
            print("❌ SubscriptionManager: Transaction verification failed - \(error)")
            #endif
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Error Handling
    
    @MainActor
    func clearError() {
        errorMessage = nil
        if case .error = subscriptionState {
            // Reset to appropriate state based on current status
            Task {
                await checkSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current plan by product ID
    func plan(for productId: String) -> SubscriptionPlan? {
        return availablePlans.first { $0.id == productId }
    }
    
    /// Whether StoreKit is available
    var isStoreKitAvailable: Bool {
        return StoreKitService.isAvailable
    }
    
    /// Whether running in test environment
    var isTestEnvironment: Bool {
        return StoreKitService.isTestEnvironment
    }
    
    // MARK: - Integration with AuthenticationManager
    
    /// Gets the current AuthenticationManager (for guest user integration)
    /// This is a bridge method to integrate with the existing auth system
    private func getCurrentAuthManager() -> AuthenticationManager? {
        // In a real app, this would be injected or accessed through a dependency container
        // For now, we'll need to access it through the app's environment
        return nil // Will be connected when integrated into ContentView
    }
}

// MARK: - Convenience Extensions

extension SubscriptionManager {
    
    /// Whether the user has an active premium subscription
    var hasPremiumSubscription: Bool {
        return subscriptionState.isPremium && !subscriptionState.isExpired
    }
    
    /// Whether the user is on the free tier
    var isFreeTier: Bool {
        return subscriptionState.isFree
    }
    
    /// Remaining free minutes (for free tier users)
    var remainingFreeMinutes: Int {
        if case .free(let minutes) = subscriptionState {
            return minutes
        }
        return 0
    }
    
    /// Usage warning level for free tier users
    var usageWarningLevel: UsageWarningLevel {
        return subscriptionState.usageWarningLevel
    }
    
    /// Whether to show upgrade prompts
    var shouldShowUpgradePrompt: Bool {
        return subscriptionState.shouldShowUpgradePrompt
    }
    
    /// Display text for current subscription status
    var statusDisplayText: String {
        return subscriptionState.displayText
    }
    
    /// Status icon for current subscription
    var statusIcon: String {
        return subscriptionState.statusIcon
    }
}

// MARK: - Debug Description

extension SubscriptionManager: CustomStringConvertible {
    var description: String {
        return """
        SubscriptionManager(
            subscriptionState: \(subscriptionState.description)
            availablePlans: \(availablePlans.count) plans
            currentSubscription: \(currentSubscription?.description ?? "nil")
            isLoading: \(isLoading)
            canAccessAPI: \(canAccessAPI)
            hasPremiumSubscription: \(hasPremiumSubscription)
            remainingFreeMinutes: \(remainingFreeMinutes)
        )
        """
    }
}