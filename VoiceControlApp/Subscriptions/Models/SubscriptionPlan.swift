import Foundation
import StoreKit

// MARK: - Subscription Plan Model

/// Represents a subscription plan with StoreKit 2 integration
struct SubscriptionPlan: Identifiable, Codable {
    
    // MARK: - Properties
    
    let id: String                    // Product ID from App Store Connect
    let displayName: String           // "Voice Control Pro" 
    let description: String           // "Unlimited voice commands + mixing console control"
    let features: [String]            // Array of feature descriptions
    let billingPeriod: BillingPeriod  // Monthly, yearly, etc.
    let trialDuration: TrialDuration? // Free trial information
    
    // StoreKit 2 Integration (not persisted)
    var storeKitProduct: Product?     // StoreKit 2 Product (loaded at runtime)
    
    // MARK: - Computed Properties
    
    /// Formatted price from StoreKit product
    var formattedPrice: String {
        guard let product = storeKitProduct else {
            return "Loading..."
        }
        return product.displayPrice
    }
    
    /// Price value for calculations (in local currency)  
    var priceValue: Decimal {
        guard let product = storeKitProduct else {
            return 0.0
        }
        return product.price
    }
    
    /// Currency code from StoreKit product
    var currencyCode: String {
        guard let product = storeKitProduct else {
            return "USD"
        }
        return product.priceFormatStyle.currencyCode
    }
    
    /// Whether this plan is currently available for purchase
    var isAvailable: Bool {
        return storeKitProduct != nil
    }
    
    /// Display text for billing period
    var billingPeriodText: String {
        return billingPeriod.displayText
    }
    
    /// Display text for trial information
    var trialText: String? {
        return trialDuration?.displayText
    }
    
    /// Whether this plan has a free trial
    var hasTrial: Bool {
        return trialDuration != nil
    }
    
    /// Primary call-to-action text
    var actionButtonText: String {
        if hasTrial {
            return "Start Free Trial"
        } else {
            return "Subscribe"
        }
    }
    
    /// Subtitle text combining price and billing period
    var priceSubtitle: String {
        let price = formattedPrice
        let period = billingPeriod.shortDisplayText
        
        if hasTrial, let trial = trialText {
            return "\(trial), then \(price)/\(period)"
        } else {
            return "\(price)/\(period)"
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: String,
        displayName: String,
        description: String,
        features: [String],
        billingPeriod: BillingPeriod,
        trialDuration: TrialDuration? = nil,
        storeKitProduct: Product? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.features = features
        self.billingPeriod = billingPeriod
        self.trialDuration = trialDuration
        self.storeKitProduct = storeKitProduct
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case description
        case features
        case billingPeriod
        case trialDuration
        // storeKitProduct is not coded (runtime only)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        description = try container.decode(String.self, forKey: .description)
        features = try container.decode([String].self, forKey: .features)
        billingPeriod = try container.decode(BillingPeriod.self, forKey: .billingPeriod)
        trialDuration = try container.decodeIfPresent(TrialDuration.self, forKey: .trialDuration)
        storeKitProduct = nil // Will be loaded at runtime
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(description, forKey: .description)
        try container.encode(features, forKey: .features)
        try container.encode(billingPeriod, forKey: .billingPeriod)
        try container.encodeIfPresent(trialDuration, forKey: .trialDuration)
        // storeKitProduct is not encoded
    }
    
    // MARK: - StoreKit Integration Methods
    
    /// Updates this plan with a loaded StoreKit Product
    /// - Parameter product: The StoreKit Product to associate
    /// - Returns: Updated SubscriptionPlan with product information
    func withStoreKitProduct(_ product: Product) -> SubscriptionPlan {
        var updatedPlan = self
        updatedPlan.storeKitProduct = product
        return updatedPlan
    }
    
    /// Whether this plan matches a StoreKit product ID
    /// - Parameter product: The StoreKit Product to compare
    /// - Returns: True if the product IDs match
    func matches(_ product: Product) -> Bool {
        return id == product.id
    }
}

// MARK: - Billing Period

enum BillingPeriod: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"
    
    var displayText: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        case .lifetime:
            return "Lifetime"
        }
    }
    
    var shortDisplayText: String {
        switch self {
        case .monthly:
            return "month"
        case .yearly:
            return "year"
        case .lifetime:
            return "lifetime"
        }
    }
    
    var months: Int {
        switch self {
        case .monthly:
            return 1
        case .yearly:
            return 12
        case .lifetime:
            return Int.max
        }
    }
}

// MARK: - Trial Duration

struct TrialDuration: Codable {
    let duration: Int      // Number of units
    let unit: TrialUnit    // Days, weeks, months
    
    var displayText: String {
        let unitText = unit.displayText(for: duration)
        return "\(duration) \(unitText) free"
    }
    
    var totalDays: Int {
        switch unit {
        case .days:
            return duration
        case .weeks:
            return duration * 7
        case .months:
            return duration * 30 // Approximate
        }
    }
}

enum TrialUnit: String, Codable, CaseIterable {
    case days = "days"
    case weeks = "weeks"
    case months = "months"
    
    func displayText(for count: Int) -> String {
        switch self {
        case .days:
            return count == 1 ? "day" : "days"
        case .weeks:
            return count == 1 ? "week" : "weeks"
        case .months:
            return count == 1 ? "month" : "months"
        }
    }
}

// MARK: - Predefined Plans

extension SubscriptionPlan {
    
    /// Predefined subscription plans for Voice Control Pro
    static let availablePlans: [SubscriptionPlan] = [
        .monthlyPro,
        .yearlyPro
    ]
    
    /// Monthly Voice Control Pro subscription
    static let monthlyPro = SubscriptionPlan(
        id: "com.voicecontrol.app.pro.monthly",
        displayName: "Voice Control Pro",
        description: "Unlimited voice commands + mixing console control",
        features: [
            "Unlimited AssemblyAI voice recognition",
            "Advanced mixing console control",
            "Cloud sync across devices", 
            "Priority customer support",
            "Premium voice processing features"
        ],
        billingPeriod: .monthly,
        trialDuration: TrialDuration(duration: 1, unit: .months)
    )
    
    /// Yearly Voice Control Pro subscription (better value)
    static let yearlyPro = SubscriptionPlan(
        id: "com.voicecontrol.app.pro.yearly",
        displayName: "Voice Control Pro Annual",
        description: "Unlimited voice commands + mixing console control (Best Value)",
        features: [
            "Unlimited AssemblyAI voice recognition",
            "Advanced mixing console control", 
            "Cloud sync across devices",
            "Priority customer support",
            "Premium voice processing features",
            "Save 17% compared to monthly"
        ],
        billingPeriod: .yearly,
        trialDuration: TrialDuration(duration: 1, unit: .months)
    )
    
    /// Gets a plan by its product ID
    /// - Parameter productId: The App Store Connect product identifier
    /// - Returns: The matching SubscriptionPlan or nil
    static func plan(for productId: String) -> SubscriptionPlan? {
        return availablePlans.first { $0.id == productId }
    }
    
    /// Gets a plan by its StoreKit Product
    /// - Parameter product: The StoreKit Product
    /// - Returns: The matching SubscriptionPlan or nil
    static func plan(for product: Product) -> SubscriptionPlan? {
        return plan(for: product.id)
    }
}

// MARK: - Plan Comparison

extension SubscriptionPlan: Equatable {
    static func == (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SubscriptionPlan: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Purchase Options

struct PurchaseOption {
    let subscriptionPlan: SubscriptionPlan
    let product: Product
    let introductoryOffer: Product.SubscriptionOffer?
    let promotionalOffer: Product.SubscriptionOffer?
    
    var effectivePrice: Decimal {
        // Check for introductory offer first
        if let introOffer = introductoryOffer {
            return introOffer.price
        }
        
        // Check for promotional offer
        if let promoOffer = promotionalOffer {
            return promoOffer.price
        }
        
        // Regular price
        return product.price
    }
    
    var displayPrice: String {
        // Check for introductory offer
        if let introOffer = introductoryOffer {
            let offerPrice = introOffer.price
            if offerPrice == 0 {
                return "Free"
            } else {
                return product.priceFormatStyle.format(offerPrice)
            }
        }
        
        // Check for promotional offer
        if let promoOffer = promotionalOffer {
            let offerPrice = promoOffer.price
            if offerPrice == 0 {
                return "Free"
            } else {
                return product.priceFormatStyle.format(offerPrice)
            }
        }
        
        // Regular price
        return product.displayPrice
    }
    
    var hasOffer: Bool {
        return introductoryOffer != nil || promotionalOffer != nil
    }
}

// MARK: - Debug Description

extension SubscriptionPlan {
    var debugInfo: String {
        return """
        SubscriptionPlan(
            id: \(id)
            displayName: \(displayName)
            billingPeriod: \(billingPeriod.rawValue)
            hasTrial: \(hasTrial)
            isAvailable: \(isAvailable)
            formattedPrice: \(formattedPrice)
            features: \(features.count) items
        )
        """
    }
}