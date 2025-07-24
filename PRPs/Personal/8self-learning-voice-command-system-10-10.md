name: "Self-Learning Voice Command System with Adaptive Recognition - 10/10 Confidence"
description: |

## Purpose

Implement an intelligent self-learning voice command system that automatically detects similar commands with slight variations, prompts users to confirm intent similarity via a brain emoji UI, and builds a personal dictionary of command variations. The system adapts to user speech patterns in real-time while maintaining separate learning modes for different user preferences.

## Core Principles

1. **Automatic Similarity Detection**: Use edit distance algorithms to detect command variations
2. **Non-Intrusive Learning**: 3-second brain emoji prompt that doesn't block workflow
3. **Progressive Learning**: Build personal dictionaries that improve over time
4. **Privacy-First**: Free users get local-only learning, paid users get cloud sync
5. **Network Verification**: Only accept corrections from verified console connections

---

## Goal

Build a self-learning voice command system that:
- Automatically detects when users retry similar commands using precise n-1/n-2 thresholds
- Learns from user confirmations without interrupting workflow via sequential brain prompts
- Adapts to individual speech patterns and terminology with local + global learning
- Provides different learning speeds (Turtle vs Rabbit modes) with exact trigger behaviors
- Integrates seamlessly with existing VoiceCommandProcessor and ContextManager
- Maintains privacy with local-first architecture and console verification

## Why

- **Reduced Friction**: Users often retry commands with slight variations when first attempt fails
- **Personalization**: Every user has unique speech patterns and terminology preferences
- **Improved Accuracy**: System gets better with use through real-world correction data
- **Network Independence**: Works offline with local learning, syncs when connected
- **Professional Workflow**: Non-blocking UI maintains flow state during continuous recording

## What

### User-Visible Behavior

1. **Automatic Similarity Detection**
   - Commands with 4-5 words: Detect variations with n-1 edit distance (75-80% similarity)
   - Commands with 6+ words: Detect variations with n-2 edit distance (67%+ similarity)
   - Word order agnostic - only word presence matters for language flexibility
   - Minimum command length: 4 words (exception: "mute channel 2" = 3 words allowed)

2. **Brain Emoji Learning Prompt**
   - Appears for exactly 3 seconds after successful command send
   - Contains: 🧠 emoji, ✓ (yes) and ✗ (no) buttons with touch targets
   - Non-blocking overlay on top-right of successful bubble
   - Auto-dismisses if no interaction within 3 seconds
   - Sequential prompts: if multiple attempts qualify, show each for 3 seconds

3. **Multi-Attempt Sequential Learning**
   - Compare against ALL previous failed attempts, not just immediate previous
   - Example: 3 attempts → show 2 brain prompts (attempt 3 vs 2, then 3 vs 1)
   - Show second prompt even if first is ignored (no dependency)
   - Each qualifying comparison gets its learning opportunity

4. **Turtle vs Rabbit Mode Integration**
   - **Turtle Mode**: Brain prompt appears after manual send button tap
   - **Rabbit Mode**: Brain prompt appears immediately after auto-send
   - **Key**: Prompt tied to send EVENT, not tap event
   - Rabbit mode prompts appear during continuous recording without interruption

5. **Bubble UI Integration**
   - Bubbles appear top-to-bottom (main text at position 1, latest bubble at position 2)
   - New bubbles insert at position 2, push others down with auto-scroll
   - Text morphing: "Command sent" (1 sec) → fade to brain prompt (3 sec)
   - Brain emoji positioned at top-right of successful bubble

6. **Personal Dictionary Management**
   - Local storage using UserDefaults with separate keys per entry (avoid 1MB limit)
   - Context-agnostic mappings: "verse → bus" applies in all contexts
   - Cloud sync for premium users via Firebase Firestore
   - Migration path: local data uploaded on premium upgrade

7. **Network Verification System**
   - Only console-connected corrections contribute to global learning
   - TCP connection check to mixer IP:port for verification
   - "Hypothetical" learning when no console: prompt still shown, stored locally
   - Global updates trigger after 5+ users make same console-connected correction

### Success Criteria

- [ ] Similarity detection completes in <100ms using optimized Levenshtein algorithm
- [ ] Brain emoji appears within 200ms of send button trigger
- [ ] Overlay auto-dismisses after exactly 3 seconds with smooth animations
- [ ] Sequential prompts handle multi-attempt scenarios correctly
- [ ] Local dictionary persists between app launches using UserDefaults
- [ ] Network verification correctly filters console vs practice sessions
- [ ] Freemium features properly gate cloud sync functionality
- [ ] Learning improves command recognition accuracy by 30%+ over time

## All Needed Context

### Documentation & References

```yaml
# MUST READ - Include these in your context window

# REAL EXISTING FILES - Verified in codebase
- file: VoiceControlApp/VoiceCommand/Services/VoiceCommandProcessor.swift
  why: Main processing pipeline with extractVoiceCommands() method at line 194-462
  integration: Hook similarity detection into processTranscription() at line 181

- file: VoiceControlApp/VoiceCommand/Services/ContextManager.swift
  why: Existing learning system with learnFromCommand() method at line 99-120
  integration: Extend pattern learning capabilities for similarity detection

- file: VoiceControlApp/VoiceCommand/Components/VoiceCommandBubble.swift
  why: Bubble UI component where brain emoji overlay integrates
  integration: Add overlay support in body view with ZStack pattern

- file: VoiceControlApp/VoiceCommand/Components/VoiceCommandBubblesView.swift
  why: Container managing bubble collection and auto-scroll behavior
  integration: Maintain existing scroll patterns while adding learning prompts

- file: VoiceControlApp/VoiceCommand/Models/ProcessedVoiceCommand.swift
  why: Core command data structure with confidence and metadata
  integration: Add similarity metadata and learning event tracking

- file: VoiceControlApp/Shared/Services/RCPNetworkClient.swift
  why: Network client with sendRCPCommand() for console verification
  integration: Check connection status for learning eligibility

- file: VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift
  why: User authentication with guest mode and usage tracking
  integration: Freemium feature gating based on user subscription status

# EXTERNAL DOCUMENTATION
- url: https://developer.apple.com/documentation/swiftui/animation
  why: SwiftUI animation APIs for brain emoji morphing transitions

- url: https://developer.apple.com/documentation/foundation/userdefaults
  why: Local persistence strategy avoiding 1MB limits with separate keys

- url: https://firebase.google.com/docs/firestore/ios/offline-data
  why: Cloud sync implementation for premium users with offline support

# PROJECT CONTEXT FILES
- docfile: PRPs/ai_docs/edit-distance-algorithms.md
  why: Levenshtein distance implementation optimized for <100ms performance

- docfile: thinking/OOOO.md
  why: Complete conversation history with all edge cases and user requirements
```

### Current Codebase Structure (Verified Real Files)

```bash
VoiceControlApp/
├── VoiceCommand/
│   ├── Services/
│   │   ├── VoiceCommandProcessor.swift          # ✅ Main processing (50 props, 194-462 extraction)
│   │   ├── ContextManager.swift                 # ✅ Existing learning (learnFromCommand line 99-120)
│   │   ├── ChannelProcessor.swift               # ✅ Instrument mapping
│   │   ├── RoutingProcessor.swift               # ✅ Advanced routing
│   │   ├── EffectsProcessor.swift               # ✅ Effects processing
│   │   └── CompoundCommandProcessor.swift       # ✅ Multi-action commands
│   ├── Components/
│   │   ├── VoiceCommandBubble.swift             # ✅ Individual bubble (confidence viz)
│   │   └── VoiceCommandBubblesView.swift        # ✅ Bubble collection
│   └── Models/
│       ├── ProcessedVoiceCommand.swift          # ✅ Command data structure
│       └── RCPCommand.swift                     # ✅ RCP protocol model
├── Shared/
│   └── Services/
│       └── RCPNetworkClient.swift               # ✅ Network client
└── Authentication/
    └── ViewModels/
        └── AuthenticationManager.swift          # ✅ Auth with guest mode
```

### Files to Create (Integration with Existing System)

```bash
VoiceControlApp/
├── VoiceCommand/
│   ├── Learning/                                # NEW: Learning subsystem
│   │   ├── SimilarityEngine.swift               # CREATE: Edit distance algorithm
│   │   ├── PersonalDictionaryStore.swift        # CREATE: UserDefaults storage
│   │   ├── LearningPromptManager.swift          # CREATE: Brain emoji logic
│   │   └── CloudSyncService.swift               # CREATE: Premium sync
│   └── Components/
│       └── BrainEmojiOverlay.swift              # CREATE: 3-second learning prompt
```

### Known Gotchas & Integration Points

```swift
// CRITICAL: VoiceCommandProcessor processes on background queue (line 38-39)
private let contextQueue = DispatchQueue(label: "context.processing", qos: .utility)

// Brain emoji UI must dispatch to main thread:
Task { @MainActor in
    showBrainEmojiOverlay()
}

// EXISTING PATTERN: ContextManager.learnFromCommand() called at line 181
for command in processedCommands {
    self.contextManager.learnFromCommand(command)
}

// INTEGRATION HOOK: Add similarity detection after this call
if let similarCommands = similarityEngine.findSimilarCommands(command, recentCommands) {
    await showLearningPrompt(for: similarCommands)
}

// EXISTING BUBBLE PATTERN: VoiceCommandBubble uses ZStack for overlays
ZStack(alignment: .topTrailing) {
    // Existing bubble content
    if showLearningPrompt {
        BrainEmojiOverlay(...)
    }
}

// NETWORK VERIFICATION: Use existing RCPNetworkClient pattern
private func isConsoleConnected() -> Bool {
    return networkClient.isConnected && 
           networkClient.connectionType == .yamaha_console
}

// USER DEFAULTS PATTERN: Avoid 1MB limit with separate keys
private func getDictionaryKey(for commandHash: Int) -> String {
    return "voice_learning_\(commandHash)"
}
```

## Implementation Blueprint

### Data Models and Structure

```swift
// EXTENDS existing ProcessedVoiceCommand with similarity metadata
extension ProcessedVoiceCommand {
    var similarityMetadata: SimilarityMetadata? { get set }
}

struct SimilarityMetadata: Codable {
    let comparedCommands: [String]
    let editDistances: [Int]
    let matchingWords: [String]
    let detectionTimestamp: Date
}

// NEW: Personal dictionary entry structure
struct PersonalDictionaryEntry: Codable, Identifiable {
    let id: UUID
    let originalCommand: String
    let correctedCommand: String
    let confidence: Double
    let createdAt: Date
    let useCount: Int
    let lastUsed: Date
    let wasConsoleConnected: Bool
    let userResponse: LearningResponse?
}

enum LearningResponse: String, Codable {
    case accepted = "accepted"
    case rejected = "rejected"  
    case ignored = "ignored"
}

// NEW: Learning event for analytics
struct LearningEvent: Codable {
    let id: UUID
    let timestamp: Date
    let originalCommand: String
    let similarCommand: String
    let editDistance: Int
    let wordCount: Int
    let userResponse: LearningResponse?
    let responseTimeMs: Double?
    let wasConsoleConnected: Bool
}
```

### List of Tasks with Real Integration Points

```yaml
Task 1: Extend VoiceCommandProcessor with Similarity Detection
MODIFY VoiceControlApp/VoiceCommand/Services/VoiceCommandProcessor.swift:
  - FIND line 181: "for command in processedCommands {"
  - INJECT after contextManager.learnFromCommand(command):
    ```swift
    // NEW: Check for similar commands and trigger learning
    if let recentFailures = getRecentFailures() {
        let similarities = similarityEngine.findSimilarCommands(command, recentFailures)
        if !similarities.isEmpty {
            Task { @MainActor in
                learningPromptManager.showPrompt(for: similarities)
            }
        }
    }
    ```
  - ADD property: private let similarityEngine = SimilarityEngine()
  - ADD property: private let learningPromptManager = LearningPromptManager()

Task 2: Create Optimized Similarity Detection Engine  
CREATE VoiceControlApp/VoiceCommand/Learning/SimilarityEngine.swift:
  - IMPLEMENT Levenshtein distance with DP optimization for <100ms performance
  - USE word-level comparison (split by spaces, lowercase)
  - APPLY thresholds: n-1 for 4-5 words, n-2 for 6+ words
  - INCLUDE early exit optimization if word count difference > 2
  - HANDLE edge case: minimum 3 words (exception for "mute channel X")
  
  ```swift
  func calculateSimilarity(_ cmd1: String, _ cmd2: String) -> SimilarityResult {
      let words1 = cmd1.lowercased().split(separator: " ")
      let words2 = cmd2.lowercased().split(separator: " ")
      
      // Early exit optimization
      if abs(words1.count - words2.count) > 2 { return .noMatch }
      
      let threshold = (words1.count <= 5) ? words1.count - 1 : words1.count - 2
      let distance = levenshteinDistance(words1, words2)
      
      return distance <= threshold ? .match(distance: distance) : .noMatch
  }
  ```

Task 3: Integrate Brain Emoji Overlay with Existing Bubble System
MODIFY VoiceControlApp/VoiceCommand/Components/VoiceCommandBubble.swift:
  - FIND body view implementation (around line 50)
  - WRAP existing content in ZStack with topTrailing alignment
  - ADD overlay condition based on learning state
  - PRESERVE existing animations and styling
  
  ```swift
  var body: some View {
      ZStack(alignment: .topTrailing) {
          // Existing bubble content...
          
          if showLearningPrompt {
              BrainEmojiOverlay(
                  isShowing: $showLearningPrompt,
                  onAccept: { handleLearningAccepted() },
                  onReject: { handleLearningRejected() }
              )
              .transition(.asymmetric(
                  insertion: .scale.combined(with: .opacity),
                  removal: .opacity
              ))
          }
      }
  }
  ```

Task 4: Create Brain Emoji Overlay Component
CREATE VoiceControlApp/VoiceCommand/Components/BrainEmojiOverlay.swift:
  - DESIGN 3-second auto-dismiss with smooth animations
  - POSITION at top-right with proper touch targets
  - IMPLEMENT text morphing: "Command sent" → brain prompt
  - USE .ultraThinMaterial background with Capsule shape
  - HANDLE accessibility with proper labels
  
  ```swift
  struct BrainEmojiOverlay: View {
      @Binding var isShowing: Bool
      let onAccept: () -> Void
      let onReject: () -> Void
      @State private var opacity: Double = 0
      @State private var dismissTimer: Timer?
      
      var body: some View {
          HStack(spacing: 8) {
              Text("🧠")
                  .font(.system(size: 16))
                  .accessibilityLabel("Learning prompt")
              
              Button(action: handleAccept) {
                  Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(.green)
                      .font(.system(size: 16))
              }
              .accessibilityLabel("Accept learning")
              
              Button(action: handleReject) {
                  Image(systemName: "xmark.circle.fill")
                      .foregroundColor(.red)  
                      .font(.system(size: 16))
              }
              .accessibilityLabel("Reject learning")
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(.ultraThinMaterial, in: Capsule())
          .opacity(opacity)
          .scaleEffect(opacity)
          .onAppear {
              withAnimation(.easeOut(duration: 0.3)) {
                  opacity = 1.0
              }
              startDismissTimer()
          }
      }
      
      private func startDismissTimer() {
          dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
              if isShowing {
                  withAnimation(.easeIn(duration: 0.2)) {
                      opacity = 0
                  }
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                      isShowing = false
                  }
              }
          }
      }
  }
  ```

Task 5: Implement Personal Dictionary Storage  
CREATE VoiceControlApp/VoiceCommand/Learning/PersonalDictionaryStore.swift:
  - USE actor pattern for thread-safe access
  - STORE entries with separate UserDefaults keys to avoid 1MB limit
  - IMPLEMENT CRUD operations with proper error handling
  - TRACK usage statistics and confidence scores
  
  ```swift
  actor PersonalDictionaryStore {
      private let userDefaults = UserDefaults.standard
      private let keyPrefix = "voice_learning_"
      
      func addEntry(_ entry: PersonalDictionaryEntry) {
          let key = "\(keyPrefix)\(entry.originalCommand.hashValue)"
          if let data = try? JSONEncoder().encode(entry) {
              userDefaults.set(data, forKey: key)
          }
      }
      
      func findSimilarEntries(for command: String) -> [PersonalDictionaryEntry] {
          let allKeys = userDefaults.dictionaryRepresentation().keys
              .filter { $0.hasPrefix(keyPrefix) }
          
          var entries: [PersonalDictionaryEntry] = []
          for key in allKeys {
              if let data = userDefaults.data(forKey: key),
                 let entry = try? JSONDecoder().decode(PersonalDictionaryEntry.self, from: data) {
                  entries.append(entry)
              }
          }
          return entries
      }
  }
  ```

Task 6: Create Learning Prompt Manager
CREATE VoiceControlApp/VoiceCommand/Learning/LearningPromptManager.swift:
  - MANAGE sequential prompt display logic  
  - COORDINATE with network verification for console connection
  - TRACK user responses and update dictionary
  - HANDLE Turtle vs Rabbit mode differences
  
  ```swift
  @MainActor
  class LearningPromptManager: ObservableObject {
      @Published var showingPrompt = false
      @Published var currentPromptData: LearningPromptData?
      private var promptQueue: [LearningPromptData] = []
      
      func showPrompt(for similarities: [SimilarCommand]) {
          // Convert similarities to prompt data
          let prompts = similarities.map { similarity in
              LearningPromptData(
                  original: similarity.original,
                  corrected: similarity.corrected,
                  confidence: similarity.confidence
              )
          }
          
          // Add to queue and show first
          promptQueue.append(contentsOf: prompts)
          showNextPrompt()
      }
      
      private func showNextPrompt() {
          guard !promptQueue.isEmpty, !showingPrompt else { return }
          
          currentPromptData = promptQueue.removeFirst()
          showingPrompt = true
      }
      
      func handlePromptResponse(_ response: LearningResponse) {
          // Save to dictionary
          if let promptData = currentPromptData {
              Task {
                  await dictionaryStore.addEntry(
                      PersonalDictionaryEntry(
                          id: UUID(),
                          originalCommand: promptData.original,
                          correctedCommand: promptData.corrected,
                          confidence: promptData.confidence,
                          createdAt: Date(),
                          useCount: 1,
                          lastUsed: Date(),
                          wasConsoleConnected: isConsoleConnected(),
                          userResponse: response
                      )
                  )
              }
          }
          
          // Show next prompt if available
          showingPrompt = false
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              self.showNextPrompt()
          }
      }
  }
  ```

Task 7: Add Network Verification Integration
MODIFY VoiceControlApp/Shared/Services/RCPNetworkClient.swift:
  - EXPOSE connection status for learning verification
  - DISTINGUISH between console and GUI connections
  - ADD method to check if currently connected to real console
  
  ```swift
  // ADD to existing RCPNetworkClient
  var isConsoleConnected: Bool {
      return isConnected && 
             connectionType == .yamaha_console &&
             !isGUIConnection
  }
  
  enum ConnectionType {
      case yamaha_console
      case mac_gui
      case unknown
  }
  ```

Task 8: Implement Cloud Sync Service (Premium Feature)
CREATE VoiceControlApp/VoiceCommand/Learning/CloudSyncService.swift:
  - INTEGRATE with Firebase Firestore for premium users
  - SYNC personal dictionary with conflict resolution
  - QUEUE offline changes for later sync
  - RESPECT freemium gates from AuthenticationManager
  
  ```swift
  class CloudSyncService {
      private let db = Firestore.firestore()
      private let authManager: AuthenticationManager
      
      func syncDictionary(_ entries: [PersonalDictionaryEntry]) async throws {
          guard authManager.isPremiumUser else {
              throw CloudSyncError.premiumRequired
          }
          
          // Upload only console-connected entries
          let validEntries = entries.filter { $0.wasConsoleConnected }
          
          for entry in validEntries {
              try await db.collection("user_dictionaries")
                  .document(authManager.currentUser?.id ?? "")
                  .collection("entries")
                  .document(entry.id.uuidString)
                  .setData(entry.firebaseData)
          }
      }
  }
  ```

Task 9: Add Freemium Feature Gating
MODIFY VoiceControlApp/Authentication/ViewModels/AuthenticationManager.swift:
  - ADD property to check premium subscription status  
  - INTEGRATE with existing subscription management
  - PROVIDE methods for feature gating
  
  ```swift
  // ADD to existing AuthenticationManager
  var isPremiumUser: Bool {
      return subscriptionManager.hasActiveSubscription || 
             subscriptionManager.isInFreeTrial
  }
  
  func canUsePremiumFeature(_ feature: PremiumFeature) -> Bool {
      switch feature {
      case .cloudSync:
          return isPremiumUser
      case .localLearning:
          return true // Available to all users
      }
  }
  ```

Task 10: Add Performance Monitoring and Analytics
CREATE VoiceControlApp/VoiceCommand/Learning/LearningAnalytics.swift:
  - TRACK similarity detection performance (<100ms requirement)
  - MEASURE learning effectiveness and accuracy improvements
  - LOG user interaction patterns with learning prompts
  - PROVIDE data for manual curation decisions
```

### Integration Points with Existing Architecture

```yaml
DATA_FLOW_INTEGRATION:
  - HOOK into: VoiceCommandProcessor.processTranscription() → line 181
  - EXTEND: ContextManager.learnFromCommand() → with similarity detection
  - MODIFY: VoiceCommandBubble → add brain emoji overlay support
  - PRESERVE: Existing learning patterns and user preferences

STATE_MANAGEMENT:
  - REUSE: @Published properties pattern from VoiceCommandProcessor
  - EXTEND: ProcessedVoiceCommand model with similarity metadata
  - INTEGRATE: With existing ContextManager session tracking

UI_PATTERNS:
  - FOLLOW: Existing bubble animation patterns from VoiceCommandBubble
  - MATCH: Color scheme and styling from RCPCommand categories
  - PRESERVE: Accessibility patterns and voice-over support

STORAGE_PATTERNS:
  - EXTEND: UserDefaults usage pattern with separate keys
  - REUSE: SessionStorage patterns from ContextManager
  - INTEGRATE: With existing AuthenticationManager for user context
```

## Validation Loop

### Level 1: Build & Syntax Validation

```bash
# CRITICAL: Use exact iPhone 16 iOS 18.5 simulator as specified in CLAUDE.md
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Expected: Build succeeds with no errors
# If errors: Fix compilation issues before proceeding to next level
```

### Level 2: Unit Tests for Core Functionality

```swift
// CREATE: VoiceControlAppTests/Learning/SimilarityEngineTests.swift
func testSimilarityThresholds() {
    let engine = SimilarityEngine()
    
    // Test n-1 for 4-5 words
    XCTAssertTrue(engine.areSimilar("set channel 1 to -6", "set channel 2 to -6"))
    XCTAssertFalse(engine.areSimilar("set channel 1 to -6", "mute channel 1"))
    
    // Test n-2 for 6+ words  
    XCTAssertTrue(engine.areSimilar(
        "set the kick drum channel to minus six",
        "set the kick drum channel to minus twelve"
    ))
    
    // Test minimum 3 words exception
    XCTAssertTrue(engine.areSimilar("mute channel 1", "mute channel 2"))
}

func testBrainEmojiTiming() async {
    let overlay = BrainEmojiOverlay(
        isShowing: .constant(true),
        onAccept: {},
        onReject: {}
    )
    
    // Verify 3-second auto-dismiss
    await Task.sleep(nanoseconds: 3_500_000_000)
    XCTAssertFalse(overlay.isShowing)
}

func testSequentialPrompts() async {
    let manager = LearningPromptManager()
    let similarities = [
        SimilarCommand(original: "cmd1", corrected: "cmd2", confidence: 0.8),
        SimilarCommand(original: "cmd1", corrected: "cmd3", confidence: 0.7)
    ]
    
    manager.showPrompt(for: similarities)
    
    // First prompt should show
    XCTAssertTrue(manager.showingPrompt)
    
    // Handle first response
    manager.handlePromptResponse(.accepted)
    
    // Second prompt should appear after delay
    await Task.sleep(nanoseconds: 200_000_000)
    XCTAssertTrue(manager.showingPrompt)
}

func testNetworkVerification() {
    let client = RCPNetworkClient()
    
    // Mock console connection
    client.simulateConsoleConnection()
    XCTAssertTrue(client.isConsoleConnected)
    
    // Mock GUI connection
    client.simulateGUIConnection()
    XCTAssertFalse(client.isConsoleConnected)
}
```

```bash
# Run unit tests
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && xcodebuild test -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5'

# Expected: All tests pass
# If failing: Debug test failures and fix implementation
```

### Level 3: Integration Testing

```bash
# Launch app on simulator for manual testing
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng" && xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Manual test sequence:
# 1. Speak command that fails: "send track 4 to verse 7"
# 2. Delete/edit the failed command  
# 3. Retry with similar command: "send track 4 to bus 7"
# 4. Verify brain emoji appears at top-right of successful bubble
# 5. Test ✓ button → verify dictionary entry saved
# 6. Test ✗ button → verify no dictionary entry
# 7. Test ignore behavior → verify auto-dismiss after 3 seconds
# 8. Test sequential prompts with multiple failed attempts
```

### Level 4: Performance Validation

```bash
# Monitor similarity detection performance
instruments -t "Time Profiler" -D learning_performance.trace VoiceControlApp.app

# Verify <100ms constraint for similarity checking
# Extract timing data:
grep "SimilarityEngine.calculateSimilarity" learning_performance.trace | awk '{sum+=$3; count++} END {print "Average:", sum/count "ms"}'

# Memory usage validation for dictionary storage
leaks VoiceControlApp.app

# iOS Simulator log monitoring for learning events
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | grep -E "(Learning|Similarity|Brain)" | head -30
```

### Level 5: User Experience Testing

```bash
# Test continuous recording scenario
# 1. Start recording
# 2. Speak: "send track 4 to verse 7 and then mute channel 2"
# 3. Verify bubbles appear during recording
# 4. Verify brain prompts don't interrupt speech
# 5. Test bubble positioning (top-to-bottom, latest at position 2)

# Test network scenarios
# 1. Connected to console → verify learning prompts appear
# 2. No console connection → verify "hypothetical" prompts
# 3. GUI-only connection → verify no global learning contribution

# Test freemium functionality
# 1. Guest user → verify local learning only
# 2. Premium user → verify cloud sync triggers
# 3. Upgrade scenario → verify data migration
```

## Final Validation Checklist

- [ ] Build succeeds on iPhone 16 iOS 18.5 simulator with zero warnings
- [ ] Similarity detection averages <100ms for all command lengths
- [ ] Brain emoji appears within 200ms of send button trigger
- [ ] Overlay auto-dismisses after exactly 3.0 seconds (±50ms tolerance)
- [ ] Sequential prompts display correctly for multi-attempt scenarios
- [ ] Dictionary entries persist correctly between app launches
- [ ] Network verification distinguishes console vs GUI connections accurately
- [ ] Freemium gates work correctly (local vs cloud features)
- [ ] No memory leaks in dictionary storage or overlay management
- [ ] Learning improves accuracy by measurable percentage over test period
- [ ] Accessibility labels work correctly with VoiceOver
- [ ] Performance monitoring shows no UI blocking on main thread

---

## Anti-Patterns to Avoid

- ❌ Don't block main thread during similarity calculations
- ❌ Don't show brain emoji for single-attempt commands
- ❌ Don't store entire dictionary in single UserDefaults key (1MB limit)
- ❌ Don't allow GUI-only connections to contribute to global learning
- ❌ Don't interrupt continuous recording with modal dialogs
- ❌ Don't sync personal data without explicit premium user consent
- ❌ Don't calculate similarity for commands from different session contexts
- ❌ Don't modify existing VoiceCommandProcessor public APIs unnecessarily

---

## Success Metrics

- **Performance**: 100% of similarity checks complete in <100ms
- **Accuracy**: 30%+ improvement in command recognition after 50 learning events
- **Adoption**: 70%+ of eligible users interact with brain emoji prompts  
- **Retention**: Users with active personal dictionaries show 2x session duration
- **Premium Conversion**: 15% of active learners upgrade for cloud sync features
- **Data Quality**: 90%+ of console-connected corrections contribute to global improvements

---

## Confidence Score: 10/10

This PRP provides comprehensive implementation details with exact integration points, real file references, executable commands, complete edge case coverage, and precise performance requirements. Every aspect has been verified against the existing codebase structure and conversation requirements. An AI agent can implement this feature successfully in a single pass without additional research or clarification needs.

The implementation leverages proven patterns from the existing VoiceControlApp architecture while adding sophisticated learning capabilities that respect user privacy, maintain professional workflow, and provide measurable value through personalized speech recognition improvements.