import XCTest
@testable import VoiceControlApp

@MainActor
final class AuthenticationManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var authManager: AuthenticationManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        super.setUp()
        authManager = AuthenticationManager()
        
        // Clear any persisted data
        UserDefaults.standard.removeObject(forKey: "subscription_status")
        UserDefaults.standard.removeObject(forKey: "premium_usage")
    }
    
    override func tearDownWithError() throws {
        authManager = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() throws {
        XCTAssertEqual(authManager.authState, .unauthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.guestUser)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertNil(authManager.errorMessage)
        XCTAssertFalse(authManager.isPremiumUser)
        XCTAssertEqual(authManager.subscriptionStatus, .free)
    }
    
    // MARK: - Guest Mode Tests
    
    func testEnterGuestMode() async throws {
        await authManager.enterGuestMode()
        
        XCTAssertEqual(authManager.authState, .guest)
        XCTAssertNotNil(authManager.guestUser)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertNil(authManager.errorMessage)
    }
    
    func testExitGuestMode() async throws {
        await authManager.enterGuestMode()
        XCTAssertEqual(authManager.authState, .guest)
        
        authManager.exitGuestMode()
        
        XCTAssertEqual(authManager.authState, .unauthenticated)
        XCTAssertNil(authManager.guestUser)
    }
    
    func testUpdateGuestUsage() async throws {
        await authManager.enterGuestMode()
        
        guard let initialGuest = authManager.guestUser else {
            XCTFail("Guest user should be available")
            return
        }
        
        let initialUsage = initialGuest.totalAPIMinutesUsed
        authManager.updateGuestUsage(minutesUsed: 5)
        
        guard let updatedGuest = authManager.guestUser else {
            XCTFail("Guest user should still be available")
            return
        }
        
        XCTAssertEqual(updatedGuest.totalAPIMinutesUsed, initialUsage + 5)
    }
    
    // MARK: - Premium Feature Gating Tests
    
    func testCanAccessPremiumFeature_freeUser() throws {
        // Free user should not have access to premium features
        XCTAssertFalse(authManager.canAccessPremiumFeature(.cloudSync))
        XCTAssertFalse(authManager.canAccessPremiumFeature(.advancedAnalytics))
        XCTAssertFalse(authManager.canAccessPremiumFeature(.customCommands))
        
        // But should have access to basic features
        XCTAssertTrue(authManager.canAccessPremiumFeature(.basicVoiceCommands))
        XCTAssertTrue(authManager.canAccessPremiumFeature(.localDictionary))
    }
    
    func testCanAccessPremiumFeature_premiumUser() throws {
        authManager.updateSubscriptionStatus(.premiumMonthly)
        
        // Premium user should have access to all features
        XCTAssertTrue(authManager.canAccessPremiumFeature(.cloudSync))
        XCTAssertTrue(authManager.canAccessPremiumFeature(.advancedAnalytics))
        XCTAssertTrue(authManager.canAccessPremiumFeature(.customCommands))
        XCTAssertTrue(authManager.canAccessPremiumFeature(.basicVoiceCommands))
        XCTAssertTrue(authManager.canAccessPremiumFeature(.localDictionary))
    }
    
    func testRequiresPremiumSubscription() throws {
        XCTAssertTrue(authManager.requiresPremiumSubscription(.cloudSync))
        XCTAssertTrue(authManager.requiresPremiumSubscription(.advancedAnalytics))
        XCTAssertTrue(authManager.requiresPremiumSubscription(.customCommands))
        XCTAssertTrue(authManager.requiresPremiumSubscription(.prioritySupport))
        
        XCTAssertFalse(authManager.requiresPremiumSubscription(.basicVoiceCommands))
        XCTAssertFalse(authManager.requiresPremiumSubscription(.localDictionary))
    }
    
    // MARK: - Premium Usage Tracking Tests
    
    func testTrackPremiumFeatureUsage() throws {
        let initialUsage = authManager.getRemainingFreeUsage(for: .cloudSync)
        
        authManager.trackPremiumFeatureUsage(.cloudSync, usage: 1)
        
        let newUsage = authManager.getRemainingFreeUsage(for: .cloudSync)
        XCTAssertEqual(newUsage, initialUsage - 1)
    }
    
    func testGetRemainingFreeUsage() throws {
        let feature = PremiumFeature.cloudSync
        let expectedLimit = feature.freeTrialLimit
        
        let remainingUsage = authManager.getRemainingFreeUsage(for: feature)
        XCTAssertEqual(remainingUsage, expectedLimit)
        
        // Use some and check again
        authManager.trackPremiumFeatureUsage(feature, usage: 2)
        let updatedUsage = authManager.getRemainingFreeUsage(for: feature)
        XCTAssertEqual(updatedUsage, expectedLimit - 2)
    }
    
    func testFreeTrialLimitExceeded() throws {
        let feature = PremiumFeature.customCommands // Has limit of 3
        
        // Use up the free trial
        authManager.trackPremiumFeatureUsage(feature, usage: 3)
        
        // Should no longer have access
        XCTAssertFalse(authManager.canAccessPremiumFeature(feature))
        XCTAssertEqual(authManager.getRemainingFreeUsage(for: feature), 0)
    }
    
    // MARK: - Subscription Status Tests
    
    func testUpdateSubscriptionStatus() throws {
        authManager.updateSubscriptionStatus(.premiumYearly)
        
        XCTAssertEqual(authManager.subscriptionStatus, .premiumYearly)
        XCTAssertTrue(authManager.isPremiumUser)
    }
    
    func testSubscriptionStatusPersistence() throws {
        authManager.updateSubscriptionStatus(.premiumMonthly)
        
        // Create new manager instance to test persistence
        let newAuthManager = AuthenticationManager()
        XCTAssertEqual(newAuthManager.subscriptionStatus, .premiumMonthly)
        XCTAssertTrue(newAuthManager.isPremiumUser)
    }
    
    func testPremiumUpgradeResetsUsage() throws {
        // Use some free trial
        authManager.trackPremiumFeatureUsage(.cloudSync, usage: 3)
        let usageBeforeUpgrade = authManager.premiumUsage.getUsage(for: .cloudSync)
        XCTAssertEqual(usageBeforeUpgrade, 3)
        
        // Upgrade to premium
        authManager.updateSubscriptionStatus(.premiumMonthly)
        
        // Usage should be reset
        let usageAfterUpgrade = authManager.premiumUsage.getUsage(for: .cloudSync)
        XCTAssertEqual(usageAfterUpgrade, 0)
    }
    
    // MARK: - Paywall Data Tests
    
    func testGetPaywallData() throws {
        let paywallData = authManager.getPaywallData(for: .cloudSync)
        
        XCTAssertEqual(paywallData.triggeredByFeature, .cloudSync)
        XCTAssertEqual(paywallData.userStatus, .free)
        XCTAssertEqual(paywallData.trialPeriodDays, 7)
        XCTAssertEqual(paywallData.monthlyPrice, 9.99)
        XCTAssertEqual(paywallData.yearlyPrice, 99.99)
        XCTAssertTrue(paywallData.shouldShowTrial)
    }
    
    func testPaywallData_noTrialWhenExhausted() throws {
        // Exhaust free trial
        authManager.trackPremiumFeatureUsage(.cloudSync, usage: 5)
        
        let paywallData = authManager.getPaywallData(for: .cloudSync)
        XCTAssertFalse(paywallData.shouldShowTrial)
    }
    
    func testPaywallData_featureMessage() throws {
        let paywallData = authManager.getPaywallData(for: .advancedAnalytics)
        
        XCTAssertTrue(paywallData.featureMessage.contains("Advanced Analytics"))
        XCTAssertTrue(paywallData.featureMessage.contains("premium features"))
    }
    
    func testPaywallData_yearlySavings() throws {
        let paywallData = authManager.getPaywallData(for: .cloudSync)
        let expectedSavings = (paywallData.monthlyPrice * 12) - paywallData.yearlyPrice
        
        XCTAssertEqual(paywallData.yearlySavings, expectedSavings, accuracy: 0.01)
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() throws {
        authManager.errorMessage = "Test error"
        authManager.clearError()
        
        XCTAssertNil(authManager.errorMessage)
    }
    
    // MARK: - Premium Feature Enum Tests
    
    func testPremiumFeatureDisplayNames() throws {
        XCTAssertEqual(PremiumFeature.cloudSync.displayName, "Cloud Sync")
        XCTAssertEqual(PremiumFeature.advancedAnalytics.displayName, "Advanced Analytics")
        XCTAssertEqual(PremiumFeature.customCommands.displayName, "Custom Commands")
        XCTAssertEqual(PremiumFeature.prioritySupport.displayName, "Priority Support")
    }
    
    func testPremiumFeatureFreeTrialLimits() throws {
        XCTAssertEqual(PremiumFeature.cloudSync.freeTrialLimit, 5)
        XCTAssertEqual(PremiumFeature.advancedAnalytics.freeTrialLimit, 10)
        XCTAssertEqual(PremiumFeature.customCommands.freeTrialLimit, 3)
        XCTAssertEqual(PremiumFeature.prioritySupport.freeTrialLimit, 1)
        XCTAssertEqual(PremiumFeature.basicVoiceCommands.freeTrialLimit, Int.max)
        XCTAssertEqual(PremiumFeature.localDictionary.freeTrialLimit, Int.max)
    }
    
    // MARK: - Subscription Status Enum Tests
    
    func testSubscriptionStatusIsPremium() throws {
        XCTAssertFalse(SubscriptionStatus.free.isPremium)
        XCTAssertFalse(SubscriptionStatus.trial.isPremium)
        XCTAssertTrue(SubscriptionStatus.premiumMonthly.isPremium)
        XCTAssertTrue(SubscriptionStatus.premiumYearly.isPremium)
        XCTAssertTrue(SubscriptionStatus.lifetime.isPremium)
    }
    
    func testSubscriptionStatusDisplayNames() throws {
        XCTAssertEqual(SubscriptionStatus.free.displayName, "Free")
        XCTAssertEqual(SubscriptionStatus.trial.displayName, "Free Trial")
        XCTAssertEqual(SubscriptionStatus.premiumMonthly.displayName, "Premium Monthly")
        XCTAssertEqual(SubscriptionStatus.premiumYearly.displayName, "Premium Yearly")
        XCTAssertEqual(SubscriptionStatus.lifetime.displayName, "Lifetime Premium")
    }
    
    // MARK: - Premium Usage Tracker Tests
    
    func testPremiumUsageTracker_trackUsage() throws {
        var tracker = PremiumUsageTracker()
        
        tracker.trackUsage(feature: .cloudSync, amount: 3)
        XCTAssertEqual(tracker.getUsage(for: .cloudSync), 3)
        
        tracker.trackUsage(feature: .cloudSync, amount: 2)
        XCTAssertEqual(tracker.getUsage(for: .cloudSync), 5)
    }
    
    func testPremiumUsageTracker_resetForNewBillingPeriod() throws {
        var tracker = PremiumUsageTracker()
        
        tracker.trackUsage(feature: .cloudSync, amount: 5)
        tracker.trackUsage(feature: .advancedAnalytics, amount: 3)
        
        XCTAssertGreaterThan(tracker.totalUsage, 0)
        
        tracker.resetForNewBillingPeriod()
        
        XCTAssertEqual(tracker.totalUsage, 0)
        XCTAssertEqual(tracker.getUsage(for: .cloudSync), 0)
        XCTAssertEqual(tracker.getUsage(for: .advancedAnalytics), 0)
    }
}