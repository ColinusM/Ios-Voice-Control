name: "StoreKit 2 Implementation with Guest Mode and Optional Authentication"
description: |

## Goal

Implement StoreKit 2 subscription system that allows guest users to access the iOS Voice Control app without mandatory authentication (complying with Apple Guideline 2.1), while offering premium subscriptions to manage API costs and providing optional authentication for cross-device sync.

**End State:** Users can immediately use voice controls with free tier (1 hour of AssemblyAI API usage), upgrade to unlimited via $4.99/month subscription with 1-month free trial, and optionally sign in for cross-device account sync.

## Why

- **Apple Compliance**: Guideline 2.1 requires apps to be usable without mandatory login unless core functionality demands it
- **API Cost Management**: AssemblyAI API costs $0.17/hour - need usage limits and premium subscriptions for sustainability  
- **User Experience**: Remove friction while preserving authentication as value-add for advanced features
- **Revenue Model**: Freemium approach (1 hour free usage) with subscription monetization for unlimited API access
- **Cross-Device Sync**: Optional authentication enables cloud backup and multi-device access

## What

Transform the current mandatory authentication app into a guest-first experience with optional premium subscriptions:

### User Flow Changes
1. **Welcome Screen**: "Try Voice Control" (guest) vs "Sign In for Full Features" 
2. **Guest Mode**: 1 hour of free AssemblyAI API usage, real-time usage tracking with clear remaining time display
3. **Premium Subscription**: $4.99/month unlimited API access, 1-month free trial (via StoreKit 2)
4. **Optional Auth**: Available for cross-device sync, cloud backup, account management
5. **Usage Transparency**: Clear display of remaining free credits, early notification when approaching limits

### Success Criteria

- [ ] App launches directly to guest mode without authentication gate
- [ ] Guest users can access core voice control features with 1 hour of free API usage
- [ ] Clear display of remaining free usage time in the app interface
- [ ] Early notifications when approaching usage limits (at 75% and 90% usage)
- [ ] StoreKit 2 subscription system prevents API overuse costs
- [ ] 1-month free trial works properly in App Store Connect
- [ ] Authentication remains available as optional upgrade for cross-device features
- [ ] Subscription status properly gates API calls to prevent cost overruns
- [ ] iOS Simulator testing works properly with iPhone 16 iOS 18.5

## All Needed Context

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- url: https://developer.apple.com/storekit/
  why: Official StoreKit 2 framework documentation and SwiftUI integration patterns

- url: https://developer.apple.com/documentation/storekit/
  why: API reference for Transaction.currentEntitlements, Product.purchase patterns

- url: https://developer.apple.com/videos/play/wwdc2021/10114/
  why: "Meet StoreKit 2" WWDC session with async/await patterns and subscription management

- url: https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/
  why: Production-ready StoreKit 2 implementation with comprehensive error handling

- url: https://developer.apple.com/app-store/review/guidelines/
  section: "2.1 Information Needed"
  critical: Apps may not require users to enter personal information to function except when directly relevant to core functionality

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift
  why: MVVM patterns for state management, async/await usage, service injection patterns to replicate

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/ContentView.swift
  why: Current mandatory auth gate that needs modification for guest access

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/Authentication/Models/AuthenticationState.swift
  why: State enum pattern to extend with .guest case

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/Shared/Utils/Constants.swift
  why: Configuration patterns for adding subscription-related constants
```

### Current Codebase tree (relevant portions)

```bash
VoiceControlApp/
├── VoiceControlAppApp.swift              # App entry point with Firebase config
├── ContentView.swift                     # ROOT AUTH GATE - needs modification for guest access
├── VoiceControlMainView.swift            # Main app interface - needs guest/premium UI
├── Authentication/
│   ├── Models/
│   │   └── AuthenticationState.swift    # Auth states - needs .guest case
│   ├── ViewModels/
│   │   └── AuthenticationManager.swift  # State management - pattern to follow
│   ├── Services/
│   │   ├── GoogleSignInService.swift    # Service patterns to replicate
│   │   └── FirebaseAuthService.swift    # Error handling patterns
│   └── Views/
│       └── AuthenticationView.swift     # Auth UI - to be made optional
├── SpeechRecognition/
│   └── AssemblyAIStreamer.swift         # API usage - needs subscription gating
└── Shared/
    ├── Utils/
    │   └── Constants.swift               # Config - needs subscription constants
    └── Components/                       # Reusable UI patterns
```

### Desired Codebase tree with files to be added

```bash
VoiceControlApp/
├── ContentView.swift                     # MODIFIED: Guest + auth routing
├── VoiceControlMainView.swift            # MODIFIED: Guest/premium UI variants
├── Authentication/
│   ├── Models/
│   │   ├── AuthenticationState.swift    # MODIFIED: Add .guest case
│   │   └── GuestUser.swift              # NEW: Guest user model
│   ├── ViewModels/
│   │   └── AuthenticationManager.swift  # MODIFIED: Guest mode methods
│   └── Views/
│       └── WelcomeView.swift             # NEW: Guest vs sign-in choice
├── Subscriptions/                        # NEW: Complete subscription system
│   ├── Models/
│   │   ├── SubscriptionPlan.swift       # Product definitions
│   │   ├── SubscriptionState.swift      # Subscription status enum
│   │   ├── SubscriptionError.swift      # StoreKit error handling
│   │   └── PurchaseResult.swift         # Transaction results
│   ├── Services/
│   │   └── StoreKitService.swift        # Main StoreKit 2 service
│   ├── ViewModels/
│   │   └── SubscriptionManager.swift    # Central subscription state
│   ├── Views/
│   │   ├── SubscriptionView.swift       # Main subscription screen
│   │   └── PaywallView.swift            # Upgrade prompts
│   └── Components/
│       └── PlanCardView.swift           # Subscription plan cards
└── Shared/Utils/
    └── Constants.swift                   # MODIFIED: Add subscription config
```

### Known Gotchas of our codebase & Library Quirks

```swift
// CRITICAL: iPhone 16 iOS 18.5 Simulator Only - from CLAUDE.md
// Use this exact build command for testing:
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

// CRITICAL: StoreKit 2 requires iOS 15.0+ minimum
// Current app targets iOS 16.0+ so this is compatible

// CRITICAL: StoreKit Testing in Simulator
// StoreKit purchases work in simulator via StoreKit Testing framework
// No real App Store purchases needed for development

// CRITICAL: Firebase + Google Sign-In are bypassed in simulator (per CLAUDE.md)
// This actually helps with guest mode testing

// CRITICAL: API Cost Management Pattern
// AssemblyAI costs $0.17/hour - subscription must gate API access
// Pattern: Check subscription status AND usage time BEFORE every API call
// Guest users get 1 hour of free API usage (worth $0.17)

// CRITICAL: App Store Connect Configuration Required
// Must create subscription products before StoreKit 2 can load them
// Product IDs must match exactly between code and App Store Connect

// CRITICAL: MVVM Pattern Consistency
// Follow exact patterns from AuthenticationManager for new SubscriptionManager
// Use @StateObject in views, @EnvironmentObject for child views
// All async operations must use @MainActor annotations
```

## Implementation Blueprint

### Data models and structure

Create the core subscription data models following the existing authentication patterns:

```swift
// SubscriptionState.swift - Mirror AuthState pattern
enum SubscriptionState: Equatable {
    case unknown
    case loading
    case free(remainingMinutes: Int)  // Minutes of API usage remaining (max 60)
    case premium(expirationDate: Date?)
    case expired
    case error(SubscriptionError)
    
    var canAccessAPI: Bool {
        switch self {
        case .premium: return true
        case .free(let minutes): return minutes > 0
        default: return false
        }
    }
    
    var usageWarningLevel: UsageWarningLevel {
        switch self {
        case .free(let minutes) where minutes <= 6:  // 10% remaining (6 minutes)
            return .critical
        case .free(let minutes) where minutes <= 15: // 25% remaining (15 minutes)
            return .warning  
        default:
            return .none
        }
    }
}

// SubscriptionPlan.swift - Product definitions
struct SubscriptionPlan: Identifiable, Codable {
    let id: String                    // Product ID from App Store Connect
    let displayName: String           // "Voice Control Pro"
    let description: String           // "Unlimited voice commands + mixing console control"
    let price: String                 // "$4.99"
    let period: String               // "month"
    let freeTrialDuration: String    // "1 month"
    let storeKitProduct: Product?    // StoreKit 2 Product
}

// GuestUser.swift - Anonymous user tracking
struct GuestUser: Codable {
    let sessionId: String
    let startDate: Date
    let deviceIdentifier: String
    var totalAPIMinutesUsed: Int  // Total minutes of API usage consumed
    
    var remainingFreeMinutes: Int {
        max(0, 60 - totalAPIMinutesUsed)  // 1 hour (60 minutes) free
    }
    
    var canMakeAPICall: Bool {
        remainingFreeMinutes > 0
    }
    
    var usagePercentage: Double {
        Double(totalAPIMinutesUsed) / 60.0  // Percentage of free hour used
    }
}
```

### List of tasks to be completed to fulfill the PRP in the order they should be completed

```yaml
Task 1: Extend Authentication State for Guest Mode
MODIFY VoiceControlApp/Authentication/Models/AuthenticationState.swift:
  - FIND enum AuthState
  - ADD case guest after unauthenticated
  - ADD computed property allowsAppAccess: Bool
  - PRESERVE existing cases and patterns

CREATE VoiceControlApp/Authentication/Models/GuestUser.swift:
  - MIRROR pattern from User.swift structure
  - ADD sessionId, startDate, deviceIdentifier, totalAPIMinutesUsed properties
  - ADD remainingFreeMinutes, canMakeAPICall, usagePercentage computed properties
  - FOLLOW Codable pattern for UserDefaults persistence

Task 2: Update Authentication Manager for Guest Support  
MODIFY VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift:
  - FIND class AuthenticationManager
  - ADD @Published var guestUser: GuestUser?
  - ADD enterGuestMode() method following async pattern from signIn methods
  - ADD exitGuestMode() method
  - MODIFY checkPersistedSession() to handle guest sessions
  - PRESERVE all existing authentication methods

Task 3: Create Subscription System Foundation
CREATE VoiceControlApp/Subscriptions/Models/SubscriptionState.swift:
  - MIRROR AuthState enum structure
  - ADD cases: unknown, loading, free(remainingMinutes), premium, expired, error
  - ADD canAccessAPI and usageWarningLevel computed properties
  - ADD UsageWarningLevel enum (none, warning, critical)
  - FOLLOW exact same pattern as AuthState

CREATE VoiceControlApp/Subscriptions/Models/SubscriptionError.swift:
  - MIRROR AuthenticationError.swift exactly
  - ADD StoreKit-specific error cases
  - IMPLEMENT LocalizedError with user-friendly messages
  - ADD static methods for StoreKit error mapping

CREATE VoiceControlApp/Subscriptions/Models/SubscriptionPlan.swift:
  - MIRROR User.swift structure patterns
  - ADD Product integration for StoreKit 2
  - ADD display properties for UI rendering
  - FOLLOW Identifiable protocol for SwiftUI lists

Task 4: Build StoreKit 2 Service Layer
CREATE VoiceControlApp/Subscriptions/Services/StoreKitService.swift:
  - MIRROR GoogleSignInService.swift service pattern
  - ADD Product.products loading with async/await
  - ADD purchase flow with Result-based error handling
  - ADD Transaction.currentEntitlements monitoring
  - ADD simulator detection following GoogleSignInService pattern
  - IMPLEMENT detailed logging with #if DEBUG blocks

Task 5: Create Subscription Manager
CREATE VoiceControlApp/Subscriptions/ViewModels/SubscriptionManager.swift:
  - MIRROR AuthenticationManager class structure exactly
  - ADD @Published properties: subscriptionState, availablePlans, currentSubscription
  - ADD async purchase methods following auth pattern
  - ADD checkSubscriptionStatus() following checkPersistedSession pattern
  - ADD StoreKitService injection following service pattern
  - IMPLEMENT Transaction.updates listener for real-time updates

Task 6: Update App Entry Point for Guest Access
MODIFY VoiceControlApp/ContentView.swift:
  - FIND switch statement on authManager.authState
  - MODIFY cases to allow both .authenticated AND .guest to access main app
  - ADD @StateObject private var subscriptionManager = SubscriptionManager()
  - ADD subscriptionManager to environmentObject chain
  - ADD new .unauthenticated case showing WelcomeView instead of AuthenticationView

CREATE VoiceControlApp/Authentication/Views/WelcomeView.swift:
  - MIRROR AuthenticationView.swift SwiftUI structure
  - ADD "Try Voice Control" primary button calling authManager.enterGuestMode()
  - ADD "Sign In for Full Features" secondary button showing auth sheet
  - ADD feature comparison text
  - FOLLOW existing view patterns and styling

Task 7: Update Main App Interface for Guest/Premium Users
MODIFY VoiceControlApp/VoiceControlMainView.swift:
  - FIND header section with user welcome
  - ADD conditional guest vs authenticated user display
  - ADD usage indicator for guest users showing remaining free minutes (e.g., "45 min free time left")
  - ADD usage progress bar or circular indicator
  - ADD early warning notifications at 75% and 90% usage
  - ADD subscription prompts when limits reached
  - MODIFY microphone button to check subscription status
  - ADD @EnvironmentObject var subscriptionManager: SubscriptionManager
  - PRESERVE all existing speech recognition functionality

Task 8: Create Subscription UI Components  
CREATE VoiceControlApp/Subscriptions/Views/SubscriptionView.swift:
  - MIRROR AuthenticationView.swift sheet presentation pattern
  - ADD subscription plans display using ForEach over availablePlans
  - ADD purchase buttons calling subscriptionManager.purchase
  - ADD loading states and error handling
  - FOLLOW existing SwiftUI view patterns

CREATE VoiceControlApp/Subscriptions/Components/PlanCardView.swift:
  - MIRROR existing component patterns from Shared/Components
  - ADD plan details display (price, features, 1-month free trial info)
  - ADD prominent purchase button
  - ADD trial duration prominently displayed
  - FOLLOW existing design system and styling

Task 9: Implement API Usage Tracking and Gating
MODIFY VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND main API call methods
  - ADD subscription status checking BEFORE API calls
  - ADD real-time usage tracking for guest users (track minutes of API usage)
  - ADD usage increment after each API session
  - ADD error handling when API limits exceeded
  - ADD warning notifications when approaching limits (75%, 90%)
  - PRESERVE all existing speech recognition functionality
  - ADD dependency injection for SubscriptionManager

Task 10: Add Subscription Configuration
MODIFY VoiceControlApp/Shared/Utils/Constants.swift:
  - FIND existing struct Constants
  - ADD nested struct Subscriptions with product IDs, limits, pricing
  - ADD API usage limits: freeMinutesPerUser = 60, apiCostPerHour = 0.17
  - ADD warning thresholds: warningAt75Percent = 45 minutes, criticalAt90Percent = 54 minutes
  - FOLLOW existing Constants structure and patterns
  - ADD StoreKit Testing configuration options

Task 11: Update App Initialization  
MODIFY VoiceControlApp/VoiceControlAppApp.swift:
  - FIND init() method with Firebase configuration
  - ADD StoreKit service initialization if needed
  - PRESERVE existing Firebase and Google Sign-In setup
  - FOLLOW existing initialization patterns
```

### Per task pseudocode as needed added to each task

```swift
// Task 1: AuthenticationState Extension
enum AuthState: Equatable {
    case unauthenticated
    case guest              // NEW: Allow app access without authentication
    case authenticating     
    case authenticated      
    case requiresBiometric  
    case error(AuthenticationError)
    
    var allowsAppAccess: Bool {
        switch self {
        case .guest, .authenticated:
            return true  // Both can access main app (Apple Guideline 2.1 compliance)
        default:
            return false
        }
    }
}

// Task 5: SubscriptionManager Core Pattern
class SubscriptionManager: ObservableObject {
    @Published var subscriptionState: SubscriptionState = .unknown
    @Published var availablePlans: [SubscriptionPlan] = []
    
    private let storeKitService = StoreKitService()
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        // PATTERN: Mirror AuthenticationManager initialization
        updateListenerTask = listenForTransactionUpdates()
        Task { await loadAvailableProducts() }
    }
    
    @MainActor
    func checkSubscriptionStatus() async {
        // PATTERN: Mirror checkPersistedSession from AuthenticationManager
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.productType == .autoRenewable {
                subscriptionState = .premium(expirationDate: transaction.expirationDate)
                return
            }
        }
        
        // No active subscription - check guest usage
        let minutesUsed = UserDefaults.standard.integer(forKey: "total_api_minutes_used")
        subscriptionState = .free(remainingMinutes: max(0, 60 - minutesUsed))
    }
}

// Task 7: API Gating Pattern
func canMakeAPICall(subscriptionManager: SubscriptionManager) -> Bool {
    // CRITICAL: Check subscription AND usage time BEFORE every $0.17/hour API call
    switch subscriptionManager.subscriptionState {
    case .premium:
        return true  // Unlimited access
    case .free(let minutes):
        return minutes > 0  // Has remaining free minutes (out of 60)
    default:
        return false  // Must handle error/unknown states
    }
}
```

### Integration Points

```yaml
STOREKIT CONFIGURATION:
  - products: Create in App Store Connect before development
  - ids: "com.voicecontrol.app.pro.monthly", "com.voicecontrol.app.pro.yearly"
  - trial: 1-month free trial (using App Store Connect dropdown option)
  - pricing: $4.99/month to align with Apple's pricing tiers

CONSTANTS:
  - add to: VoiceControlApp/Shared/Utils/Constants.swift
  - pattern: "struct Subscriptions { static let freeMinutesPerUser = 60; static let apiCostPerHour = 0.17 }"

DEPENDENCY INJECTION:
  - add to: ContentView.swift environmentObject chain
  - pattern: ".environmentObject(subscriptionManager)"

API COST MANAGEMENT:
  - integration: AssemblyAIStreamer must check subscription before API calls
  - pattern: "guard subscriptionManager.canAccessAPI else { throw APILimitError() }"

USERDEFAULTS PERSISTENCE:
  - guest usage: "total_api_minutes_used", "guest_session_start"
  - tracking: Persist total minutes used across app sessions (no daily reset)
  - warning state: Track last warning shown to avoid spam notifications
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# Run these FIRST - fix any errors before proceeding
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"

# Build for iPhone 16 iOS 18.5 simulator (MANDATORY per CLAUDE.md)
xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Expected: Build succeeds with no errors
# If errors: Read build output, fix Swift syntax/type errors, re-run
```

### Level 2: StoreKit Testing Configuration

```bash
# Create StoreKit Testing configuration file
# In Xcode: File -> New -> File -> iOS -> App Store Connect -> StoreKit Configuration File

# Add test products matching Constants:
# - Monthly: com.voicecontrol.app.pro.monthly ($4.99/month with 1-month free trial)
# - Test user accounts for subscription flows
# - Test introductory offer configuration

# Test StoreKit in simulator:
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Expected: App launches in guest mode, subscription purchase flows work in simulator
```

### Level 3: Guest Mode Integration Test

```bash
# Launch app and test guest mode flow:
# 1. App should launch directly to WelcomeView (no auth gate)
# 2. "Try Voice Control" should activate guest mode immediately  
# 3. Main app should show usage limits (60 minutes free, with remaining time displayed)
# 4. Usage warning should appear at 75% (45 min) and 90% (54 min) usage
# 5. API calls should be gated by subscription status
# 6. Paywall should appear when limits exceeded

# Test subscription flow:
# 1. Tap subscription upgrade
# 2. StoreKit purchase should work in simulator
# 3. Subscription status should update immediately
# 4. API limits should be removed for premium users

# Expected: Complete guest-to-premium flow works without authentication requirements
```

### Level 4: Authentication Integration Test

```bash
# Test optional authentication:
# 1. From guest mode, access "Sign In for Full Features"
# 2. Google Sign-In should work (bypassed in simulator per CLAUDE.md)
# 3. Premium subscription should carry over to authenticated mode
# 4. Cross-device sync features should become available

# Test mixed states:
# 1. Guest with premium subscription
# 2. Authenticated user without subscription (should have limits)
# 3. Authenticated user with premium (full features + sync)

# Expected: Authentication enhances features but doesn't gate core functionality
```

## Final validation Checklist

- [ ] App launches directly to guest mode (no mandatory auth gate)
- [ ] Guest users can access voice controls with 1 hour of free API usage
- [ ] Usage display shows remaining free minutes clearly in the UI
- [ ] Warning notifications appear at 75% and 90% usage levels
- [ ] Subscription purchase works via StoreKit 2 in simulator with 1-month trial
- [ ] API calls are properly gated by subscription status
- [ ] Premium subscription removes usage limits
- [ ] Authentication remains optional for cross-device sync
- [ ] Build succeeds with iPhone 16 iOS 18.5 simulator
- [ ] No StoreKit errors in simulator logs
- [ ] Guest usage persists across app sessions (no daily reset)
- [ ] Transaction updates work for subscription changes

---

## Anti-Patterns to Avoid

- ❌ Don't create mandatory authentication gates (violates Apple Guideline 2.1)
- ❌ Don't skip subscription status checks before API calls (will blow costs)
- ❌ Don't use hardcoded product IDs (must match App Store Connect exactly)
- ❌ Don't ignore StoreKit Testing configuration (essential for simulator testing)
- ❌ Don't break existing authentication flow (must remain optional)
- ❌ Don't use physical device testing (CLAUDE.md requires iPhone 16 iOS 18.5 simulator only)
- ❌ Don't skip transaction verification (use Transaction.currentEntitlements properly)
- ❌ Don't create new MVVM patterns (follow existing AuthenticationManager exactly)

## Success Confidence Score: 9/10

This PRP provides comprehensive context for implementing StoreKit 2 with guest mode while maintaining Apple guidelines compliance. The detailed codebase analysis, existing patterns to follow, and specific validation steps should enable successful one-pass implementation with the iOS Voice Control app's architecture.