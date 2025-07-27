import Foundation
import StoreKit
import SwiftUI

// MARK: - StoreKit 2 Service

/// Enterprise-grade StoreKit 2 service for subscription management
/// Follows the same patterns as GoogleSignInService for consistency
class StoreKitService: ObservableObject {
    
    // MARK: - Configuration
    
    private static var isConfigured = false
    private static let shared = StoreKitService()
    
    // MARK: - Published Properties (for SwiftUI integration)
    
    @Published var availableProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var transactionState: TransactionStatus = .pending
    
    // MARK: - Private Properties
    
    private var transactionListener: Task<Void, Error>?
    private let productIds: Set<String> = [
        "com.voicecontrol.app.pro.monthly",
        "com.voicecontrol.app.pro.yearly"
    ]
    
    // MARK: - Initialization
    
    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactionUpdates()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Configuration
    
    static func configure() {
        guard !isConfigured else { return }
        
        #if DEBUG
        print("🔧 StoreKitService: Starting configuration...")
        #endif
        
        #if targetEnvironment(simulator)
        #if DEBUG
        print("⚠️ StoreKitService: Running in simulator - StoreKit Testing enabled")
        #endif
        #endif
        
        isConfigured = true
        
        #if DEBUG
        print("✅ StoreKitService: Configuration completed successfully")
        #endif
    }
    
    // MARK: - Product Loading
    
    /// Loads available subscription products from App Store Connect
    /// - Returns: Result containing available products or error
    static func loadProducts() async -> Result<[Product], SubscriptionError> {
        #if DEBUG
        print("🔵 StoreKitService: Loading available products")
        #endif
        
        configure()
        
        do {
            let products = try await Product.products(for: shared.productIds)
            
            #if DEBUG
            print("✅ StoreKitService: Loaded \(products.count) products")
            for product in products {
                print("   Product: \(product.id) - \(product.displayName) (\(product.displayPrice))")
            }
            #endif
            
            await MainActor.run {
                shared.availableProducts = products
            }
            
            return .success(products)
            
        } catch {
            let subscriptionError = SubscriptionError.from(error)
            
            #if DEBUG
            print("❌ StoreKitService: Failed to load products - \(subscriptionError.localizedDescription)")
            #endif
            
            return .failure(subscriptionError)
        }
    }
    
    // MARK: - Purchase Flow
    
    /// Initiates purchase flow for a subscription product
    /// - Parameter product: The Product to purchase
    /// - Returns: Result containing purchase result or error
    static func purchase(_ product: Product) async -> Result<PurchaseResult, SubscriptionError> {
        #if DEBUG
        print("🔵 StoreKitService: Initiating purchase for \(product.id)")
        #endif
        
        configure()
        
        await MainActor.run {
            shared.transactionState = .purchasing
        }
        
        do {
            let purchaseResult = try await product.purchase()
            
            switch purchaseResult {
            case .success(let verificationResult):
                #if DEBUG
                print("✅ StoreKitService: Purchase successful")
                #endif
                
                await MainActor.run {
                    shared.transactionState = .purchased
                }
                
                // Verify the transaction
                let transaction = try checkVerified(verificationResult)
                
                // Finish the transaction
                await transaction.finish()
                
                let result = PurchaseResult(
                    product: product,
                    transaction: transaction,
                    transactionId: String(transaction.id),
                    purchaseDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate
                )
                
                #if DEBUG
                print("   Transaction ID: \(transaction.id)")
                print("   Purchase Date: \(transaction.purchaseDate)")
                if let expiration = transaction.expirationDate {
                    print("   Expiration: \(expiration)")
                }
                #endif
                
                return .success(result)
                
            case .userCancelled:
                #if DEBUG
                print("⚠️ StoreKitService: Purchase cancelled by user")
                #endif
                
                await MainActor.run {
                    shared.transactionState = .cancelled
                }
                
                return .failure(.purchaseCancelled)
                
            case .pending:
                #if DEBUG
                print("⏳ StoreKitService: Purchase pending approval")
                #endif
                
                await MainActor.run {
                    shared.transactionState = .pending
                }
                
                return .failure(.purchasePending)
                
            @unknown default:
                #if DEBUG
                print("❌ StoreKitService: Unknown purchase result")
                #endif
                
                await MainActor.run {
                    shared.transactionState = .failed
                }
                
                return .failure(.purchaseFailed(underlying: nil))
            }
            
        } catch {
            let subscriptionError = SubscriptionError.from(error)
            
            #if DEBUG
            print("❌ StoreKitService: Purchase failed - \(subscriptionError.localizedDescription)")
            #endif
            
            await MainActor.run {
                shared.transactionState = .failed
            }
            
            return .failure(subscriptionError)
        }
    }
    
    // MARK: - Subscription Status
    
    /// Checks current entitlements and returns active subscription
    /// - Returns: Result containing current subscription or error
    static func checkSubscriptionStatus() async -> Result<StoreKitSubscriptionStatus, SubscriptionError> {
        #if DEBUG
        print("🔵 StoreKitService: Checking subscription status")
        #endif
        
        configure()
        
        var currentSubscription: StoreKit.Transaction?
        var hasActiveSubscription = false
        
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is a subscription and still valid
                if transaction.productType == .autoRenewable {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            currentSubscription = transaction
                            hasActiveSubscription = true
                            
                            #if DEBUG
                            print("✅ StoreKitService: Found active subscription")
                            print("   Product ID: \(transaction.productID)")
                            print("   Expires: \(expirationDate)")
                            #endif
                        } else {
                            #if DEBUG
                            print("⚠️ StoreKitService: Found expired subscription for \(transaction.productID)")
                            #endif
                        }
                    } else {
                        // No expiration date means lifetime subscription
                        currentSubscription = transaction
                        hasActiveSubscription = true
                        
                        #if DEBUG
                        print("✅ StoreKitService: Found lifetime subscription for \(transaction.productID)")
                        #endif
                    }
                }
            } catch {
                #if DEBUG
                print("⚠️ StoreKitService: Failed to verify transaction - \(error)")
                #endif
                continue
            }
        }
        
        let status = StoreKitSubscriptionStatus(
            isActive: hasActiveSubscription,
            currentTransaction: currentSubscription,
            productId: currentSubscription?.productID,
            purchaseDate: currentSubscription?.purchaseDate,
            expirationDate: currentSubscription?.expirationDate
        )
        
        #if DEBUG
        if hasActiveSubscription {
            print("✅ StoreKitService: User has active subscription")
        } else {
            print("ℹ️ StoreKitService: No active subscription found")
        }
        #endif
        
        return .success(status)
    }
    
    // MARK: - Restore Purchases
    
    /// Restores previous purchases
    /// - Returns: Result containing restored products or error
    static func restorePurchases() async -> Result<[Product], SubscriptionError> {
        #if DEBUG
        print("🔵 StoreKitService: Restoring purchases")
        #endif
        
        configure()
        
        do {
            try await AppStore.sync()
            
            var restoredProducts: [Product] = []
            let availableProducts = shared.availableProducts
            
            // Check current entitlements after sync
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try StoreKitService.checkVerified(result)
                    
                    // Find the corresponding product
                    if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                        restoredProducts.append(product)
                    }
                } catch {
                    #if DEBUG
                    print("⚠️ StoreKitService: Failed to verify restored transaction - \(error)")
                    #endif
                    continue
                }
            }
            
            #if DEBUG
            print("✅ StoreKitService: Restored \(restoredProducts.count) purchases")
            #endif
            
            await MainActor.run {
                shared.purchasedProducts = restoredProducts
            }
            
            return .success(restoredProducts)
            
        } catch {
            let subscriptionError = SubscriptionError.from(error)
            
            #if DEBUG
            print("❌ StoreKitService: Restore failed - \(subscriptionError.localizedDescription)")
            #endif
            
            return .failure(subscriptionError)
        }
    }
    
    // MARK: - Transaction Verification
    
    /// Verifies a transaction result and returns the verified transaction
    /// - Parameter result: The VerificationResult to check
    /// - Throws: SubscriptionError if verification fails
    /// - Returns: The verified Transaction
    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            // StoreKit has parsed the JWS but failed verification
            #if DEBUG
            print("❌ StoreKitService: Transaction verification failed - \(error)")
            #endif
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            // The result is verified, return the unwrapped value
            return safe
        }
    }
    
    // MARK: - Transaction Monitoring
    
    /// Listen for transaction updates
    /// - Returns: Task monitoring transaction updates
    @Sendable
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try StoreKitService.checkVerified(result)
                    
                    #if DEBUG
                    print("🔄 StoreKitService: Transaction update received")
                    print("   Product ID: \(transaction.productID)")
                    print("   Transaction ID: \(transaction.id)")
                    #endif
                    
                    // Update UI on main actor
                    await MainActor.run {
                        // Handle transaction update
                        self.handleTransactionUpdate(transaction)
                    }
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                } catch {
                    #if DEBUG
                    print("❌ StoreKitService: Failed to handle transaction update - \(error)")
                    #endif
                }
            }
        }
    }
    
    /// Handle transaction updates from StoreKit
    /// - Parameter transaction: The updated transaction
    @MainActor
    private func handleTransactionUpdate(_ transaction: StoreKit.Transaction) {
        // Update purchased products list
        Task {
            let result = await Self.loadProducts()
            if case .success(let products) = result {
                // Update purchased products based on current entitlements
                let statusResult = await Self.checkSubscriptionStatus()
                if case .success(let status) = statusResult, status.isActive {
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        if !purchasedProducts.contains(where: { $0.id == product.id }) {
                            purchasedProducts.append(product)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get the shared instance for SwiftUI integration
    static var instance: StoreKitService {
        return shared
    }
    
    /// Whether StoreKit is available on this device
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return true // StoreKit Testing works in simulator
        #else
        return AppStore.canMakePayments
        #endif
    }
    
    /// Whether running in test environment
    static var isTestEnvironment: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Purchase Result

struct PurchaseResult {
    let product: Product
    let transaction: StoreKit.Transaction
    let transactionId: String
    let purchaseDate: Date
    let expirationDate: Date?
    
    var isSubscription: Bool {
        return transaction.productType == .autoRenewable
    }
    
    var isValid: Bool {
        if let expiration = expirationDate {
            return expiration > Date()
        }
        return true // No expiration means lifetime
    }
}

// MARK: - Subscription Status

struct StoreKitSubscriptionStatus {
    let isActive: Bool
    let currentTransaction: StoreKit.Transaction?
    let productId: String?
    let purchaseDate: Date?
    let expirationDate: Date?
    
    var isExpired: Bool {
        guard let expiration = expirationDate else {
            return false // No expiration means lifetime
        }
        return expiration <= Date()
    }
    
    var daysUntilExpiration: Int? {
        guard let expiration = expirationDate else {
            return nil // No expiration
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
        return max(0, days ?? 0)
    }
    
    var subscriptionPlan: SubscriptionPlan? {
        guard let productId = productId else { return nil }
        return SubscriptionPlan.plan(for: productId)
    }
}

// MARK: - Debug Description

extension PurchaseResult: CustomStringConvertible {
    var description: String {
        return """
        PurchaseResult(
            product: \(product.id)
            transactionId: \(transactionId)
            purchaseDate: \(purchaseDate)
            expirationDate: \(expirationDate?.description ?? "nil")
            isValid: \(isValid)
        )
        """
    }
}

extension StoreKitSubscriptionStatus: CustomStringConvertible {
    var description: String {
        return """
        StoreKitSubscriptionStatus(
            isActive: \(isActive)
            productId: \(productId ?? "nil")
            purchaseDate: \(purchaseDate?.description ?? "nil")
            expirationDate: \(expirationDate?.description ?? "nil")
            isExpired: \(isExpired)
            daysUntilExpiration: \(daysUntilExpiration?.description ?? "nil")
        )
        """
    }
}