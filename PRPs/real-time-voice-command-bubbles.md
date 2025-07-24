name: "Real-Time Voice Command Bubbles - Professional Audio Integration"
description: |

## Purpose

Comprehensive PRP for implementing real-time voice command bubble detection and display in iOS Voice Control app, porting professional audio command processing from Python engine to Swift with SwiftUI animations.

## Core Principles

1. **Context is King**: Complete professional audio terminology preservation and Swift architectural integration
2. **Validation Loops**: Real-time testing with iPhone 16 iOS 18.5 simulator and comprehensive testing infrastructure
3. **Information Dense**: Leveraging existing MVVM patterns, ObservableObject architecture, and SwiftUI performance optimizations
4. **Progressive Success**: Modular implementation with validated integration points

---

## Goal

Implement real-time voice command bubbles that appear instantly as professional audio commands are detected from speech recognition, displaying processed RCP commands in animated rounded rectangles with confidence indicators in a 5:5 top-down layout.

## Why

- **Enhanced User Experience**: Real-time visual feedback for voice command recognition builds user confidence and provides immediate validation
- **Professional Audio Workflow**: Essential for audio engineers who need instant confirmation that voice commands are properly interpreted
- **Integration Excellence**: Leverages existing speech recognition infrastructure and professional RCP command system
- **Performance Critical**: Real-time audio control requires <500ms response time from speech to visual confirmation

## What

Real-time command bubble system that processes speech transcription through professional audio terminology engine, generates Yamaha RCP commands, and displays animated UI bubbles with confidence scoring and professional command descriptions.

### Success Criteria

- [ ] Command bubbles appear within 500ms of voice command detection
- [ ] 90%+ accuracy for professional audio terminology recognition
- [ ] Smooth 60fps animations for bubble entrance/exit transitions
- [ ] Background processing without blocking speech recognition performance
- [ ] Professional RCP command generation with proper validation
- [ ] Confidence scoring system with visual indicators
- [ ] 5:5 layout integration with existing speech recognition UI
- [ ] Memory efficient with automatic cleanup of old commands

## All Needed Context

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- docfile: PRPs/ai_docs/professional-audio-terminology.md
  why: Complete professional audio terminology database with RCP command mappings, confidence scoring guidelines, and Swift implementation notes

- url: https://www.swiftbysundell.com/articles/writing-testable-code-when-using-swiftui/
  why: SwiftUI testing patterns for ObservableObject and @Published properties
  critical: MainActor usage and async property testing

- url: https://fatbobman.com/en/posts/list-or-lazyvstack/
  why: Performance comparison showing List > LazyVStack for real-time updates
  critical: List uses UICollectionView recycling, 23% better memory performance

- url: https://www.avanderlee.com/concurrency/detached-tasks/
  why: Task.detached best practices with MainActor.run patterns
  critical: Background processing without blocking UI updates

- url: https://medium.com/@amosgyamfi/learning-swiftui-spring-animations-the-basics-and-beyond-4fb032212487
  why: iOS 17+ spring animation presets (.smooth, .bouncy, .snappy)
  critical: Hardware-accelerated 120fps performance

- file: VoiceControlApp/SpeechRecognition/SpeechRecognitionManager.swift
  why: Existing real-time processing patterns with 100ms timer sync
  critical: Lines 272-277 show timer-based state synchronization

- file: VoiceControlApp/VoiceControlMainView.swift
  why: Current UI integration points and ObservableObject dependency injection
  critical: Lines 165-166 show service configuration pattern

- file: VoiceControlApp/Shared/Components/RecordButton.swift
  why: Existing animation patterns with spring physics and state-driven UI
  critical: Lines 96-102 show pulse animation implementation

- file: voice-command-tester/engine.py
  why: Professional audio command processing pipeline to port to Swift
  critical: Lines 402-443 show modular processor architecture
```

### Current Codebase Tree

```bash
VoiceControlApp/
├── VoiceControlAppApp.swift                 # App entry point with Firebase config
├── ContentView.swift                        # Root view with auth flow
├── VoiceControlMainView.swift               # INTEGRATION POINT - Main app interface
├── Info.plist                              # URL schemes & permissions
├── Authentication/                          # Complete auth system
│   ├── ViewModels/AuthenticationManager.swift # PATTERN REFERENCE - ObservableObject with @Published
│   └── Services/                           # Service injection patterns
├── SpeechRecognition/                      # INTEGRATION POINT - Speech processing
│   ├── SpeechRecognitionManager.swift      # CRITICAL - Real-time processing patterns
│   ├── AssemblyAIStreamer.swift           # WebSocket streaming client
│   └── Models/TranscriptionModels.swift    # Data models
├── Shared/
│   ├── Components/                         # PATTERN REFERENCE - Reusable UI
│   │   ├── RecordButton.swift             # CRITICAL - Animation patterns
│   │   └── OrbitalToggleButton.swift      # Spring animation examples
│   └── Utils/Validation.swift             # Input validation patterns
└── Subscriptions/                          # Service architecture examples

voice-command-tester/                       # SOURCE FOR PORTING
├── engine.py                              # CRITICAL - Main processing engine
├── terms.py                               # Professional terminology database
├── channels.py                            # Channel processing logic
├── routing.py                             # Audio routing commands
└── effects.py                             # Effects processing
```

### Desired Codebase Tree with New Files

```bash
VoiceControlApp/
├── VoiceCommand/                           # NEW - Voice command processing module
│   ├── Services/
│   │   ├── VoiceCommandProcessor.swift    # Main command processing service
│   │   ├── ProfessionalAudioTerms.swift   # Terminology database
│   │   ├── PatternMatcher.swift           # Regex pattern matching
│   │   └── RCPCommandGenerator.swift      # RCP command generation
│   ├── Models/
│   │   ├── VoiceCommand.swift             # Command data structures
│   │   ├── RCPCommand.swift               # RCP command models
│   │   ├── CommandPattern.swift           # Pattern matching models
│   │   └── ProcessingResult.swift         # Processing result models
│   ├── Components/
│   │   ├── VoiceCommandBubble.swift       # Individual bubble component
│   │   ├── CommandBubblesView.swift       # Bubble container view
│   │   └── ConfidenceIndicator.swift      # Confidence visualization
│   └── ViewModels/
│       └── CommandBubbleManager.swift     # Bubble state management
└── Tests/                                  # NEW - Testing infrastructure
    ├── VoiceCommandTests/
    │   ├── VoiceCommandProcessorTests.swift
    │   ├── PatternMatcherTests.swift
    │   └── RCPCommandGeneratorTests.swift
    └── UITests/
        └── CommandBubblesUITests.swift
```

### Known Gotchas of Our Codebase & Library Quirks

```swift
// CRITICAL: SpeechRecognitionManager uses 100ms timer for real-time sync
// Pattern from lines 272-277 in SpeechRecognitionManager.swift
Timer.publish(every: 0.1, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in
        // Hook into this existing timer for command processing
    }

// CRITICAL: All ObservableObject classes need @MainActor for thread safety
// Pattern from AuthenticationManager.swift line 8
@MainActor
class VoiceCommandProcessor: ObservableObject {
    @Published var commandBubbles: [CommandBubble] = []
}

// CRITICAL: Use iPhone 16 iOS 18.5 simulator ONLY (Device ID: 5B1989A0-1EC8-4187-8A99-466B20CB58F2)
// Build command from CLAUDE.md:
// xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

// CRITICAL: Spring animations must use iOS 17+ presets for hardware acceleration
// Pattern from RecordButton.swift lines 96-102
withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
    // Use .bouncy, .smooth, .snappy for built-in spring presets
}

// CRITICAL: Background processing MUST use Task.detached with MainActor.run
// Pattern for non-blocking command processing
Task.detached(priority: .background) {
    let commands = await processVoiceCommands(transcription)
    await MainActor.run {
        self.commandBubbles = commands
    }
}

// CRITICAL: List performs 23% better than LazyVStack for real-time updates
// Use List for command bubbles container, not LazyVStack
List(commandBubbles) { bubble in
    CommandBubbleView(bubble: bubble)
}

// CRITICAL: Professional audio terminology must preserve exact slang and confidence
// Terms like "crank", "bury", "hot", "cooking" have specific dB mappings
// Reference: PRPs/ai_docs/professional-audio-terminology.md

// CRITICAL: RCP commands use integer dB values (x100 format)
// -6.0 dB = -600 in RCP format
// 0 dB (unity) = 0 in RCP format
// +3.0 dB = 300 in RCP format
```

## Implementation Blueprint

### Data Models and Structure

Core data models ensure type safety and professional audio terminology accuracy.

```swift
// CRITICAL: Based on Python RCPCommand dataclass from engine.py line 14
struct RCPCommand: Identifiable, Hashable, Equatable {
    let id = UUID()
    let command: String      // "set MIXER:Current/InCh/Fader/Level 0 0 -600"
    let description: String  // "Set channel 1 to -6.0 dB"
    let confidence: Double   // 0.85 (0.0-1.0 range)
    let category: CommandCategory
    let timestamp: Date
}

// CRITICAL: Mirror Python processor categories from engine.py lines 416-427
enum CommandCategory: String, CaseIterable {
    case channelFader = "channel_fader"
    case channelMute = "channel_mute"
    case channelLabel = "channel_label"
    case routing = "routing"
    case pan = "pan"
    case scene = "scene"
    case dca = "dca"
    case effects = "effects"
    case dynamics = "dynamics"
    case context = "context"
}

// CRITICAL: Command bubble with animation state
struct CommandBubble: Identifiable, Hashable {
    let id = UUID()
    let rcpCommand: RCPCommand
    let animationState: BubbleAnimationState
    let displayDuration: TimeInterval
    
    enum BubbleAnimationState {
        case entering, visible, exiting
    }
}

// CRITICAL: Professional terminology from terms.py ported to Swift
struct ProfessionalAudioMapping {
    static let instrumentAliases: [String: String] = [
        "vox": "vocals",
        "vocal": "vocals", 
        "kick": "kick drum",
        "bd": "kick drum",
        "snare": "snare drum",
        // ... complete mapping from PRPs/ai_docs/professional-audio-terminology.md
    ]
    
    static let dbKeywords: [String: Int] = [
        "unity": 0,
        "hot": 300,      // +3.0 dB
        "cooking": 300,  // +3.0 dB  
        "bury": -1500,   // -15.0 dB
        "quiet": -1000   // -10.0 dB
    ]
}
```

### List of Tasks to be Completed in Order

```yaml
Task 1 - Setup Testing Infrastructure:
CREATE VoiceControlAppTests.xctest target:
  - ADD to Xcode project with proper bundle identifier
  - CONFIGURE for iPhone 16 iOS 18.5 simulator testing
  - INSTALL SwiftLint via Homebrew and configure .swiftlint.yml
  - MIRROR testing patterns from existing iOS projects

Task 2 - Core Data Models:
CREATE VoiceControlApp/VoiceCommand/Models/RCPCommand.swift:
  - MIRROR structure from Python RCPCommand dataclass (engine.py:14)
  - IMPLEMENT Identifiable, Hashable, Equatable protocols
  - ADD confidence scoring with 0.0-1.0 range validation

CREATE VoiceControlApp/VoiceCommand/Models/CommandBubble.swift:
  - COMBINE RCPCommand with animation state
  - ADD timestamp for automatic cleanup
  - IMPLEMENT bubble lifecycle management

Task 3 - Professional Audio Terminology Service:
CREATE VoiceControlApp/VoiceCommand/Services/ProfessionalAudioTerms.swift:
  - PORT terminology database from terms.py (lines 12-89)
  - IMPLEMENT fast Dictionary lookups for instrument aliases
  - PRESERVE exact professional slang terms and dB mappings
  - ADD confidence scoring for terminology recognition

Task 4 - Pattern Matching Engine:
CREATE VoiceControlApp/VoiceCommand/Services/PatternMatcher.swift:
  - PORT regex patterns from Python engine processors
  - USE NSRegularExpression with pre-compiled patterns
  - IMPLEMENT confidence calculation based on pattern specificity
  - ADD professional audio command categories

Task 5 - Voice Command Processor Service:
CREATE VoiceControlApp/VoiceCommand/Services/VoiceCommandProcessor.swift:
  - MIRROR VoiceCommandEngine architecture from engine.py:17
  - IMPLEMENT @MainActor ObservableObject pattern
  - ADD @Published properties for real-time bubble updates
  - INTEGRATE with existing SpeechRecognitionManager timer (100ms sync)

Task 6 - RCP Command Generation:
CREATE VoiceControlApp/VoiceCommand/Services/RCPCommandGenerator.swift:
  - PORT RCP command formatting from Python processors
  - IMPLEMENT dB value conversion (float to integer x100)
  - ADD channel/DCA number validation (1-40 channels, 1-8 DCAs)
  - PRESERVE exact RCP protocol syntax

Task 7 - Command Bubble UI Components:
CREATE VoiceControlApp/VoiceCommand/Components/VoiceCommandBubble.swift:
  - FOLLOW RecordButton.swift animation patterns (lines 96-102)
  - IMPLEMENT confidence color coding (green/orange/red)
  - ADD spring entrance animations with .bouncy preset
  - DISPLAY RCP command and human description

CREATE VoiceControlApp/VoiceCommand/Components/CommandBubblesView.swift:
  - USE List (not LazyVStack) for better real-time performance
  - IMPLEMENT automatic cleanup after 30 seconds
  - ADD smooth insertion/removal animations
  - LIMIT to 10 visible bubbles maximum

Task 8 - Bubble State Management:
CREATE VoiceControlApp/VoiceCommand/ViewModels/CommandBubbleManager.swift:
  - FOLLOW AuthenticationManager.swift ObservableObject pattern
  - IMPLEMENT @Published bubble array for SwiftUI updates
  - ADD background command processing with Task.detached
  - INTEGRATE with SpeechRecognitionManager dependency injection

Task 9 - Main UI Integration:
MODIFY VoiceControlApp/VoiceControlMainView.swift:
  - FIND speech text box container (lines 66-104)
  - ADD CommandBubblesView below existing speech UI
  - IMPLEMENT 5:5 layout with HStack for side-by-side display
  - PRESERVE existing orbital controls and status indicators
  - INJECT CommandBubbleManager via environmentObject pattern

Task 10 - SpeechRecognitionManager Integration:
MODIFY VoiceControlApp/SpeechRecognition/SpeechRecognitionManager.swift:
  - ADD VoiceCommandProcessor property initialization
  - HOOK into existing transcription update pipeline (line 295)
  - TRIGGER command processing on transcription changes
  - MAINTAIN non-blocking background processing

Task 11 - Comprehensive Testing:
CREATE VoiceCommandTests/VoiceCommandProcessorTests.swift:
  - TEST professional audio terminology recognition accuracy
  - VERIFY RCP command generation correctness
  - VALIDATE confidence scoring algorithms
  - MOCK SpeechRecognitionManager for isolated testing

CREATE UITests/CommandBubblesUITests.swift:
  - TEST real-time bubble appearance timing (<500ms)
  - VERIFY animation smoothness and performance
  - VALIDATE UI layout in different orientations
  - TEST memory usage during extended sessions

Task 12 - Performance Optimization:
OPTIMIZE VoiceCommandProcessor background processing:
  - IMPLEMENT command deduplication logic
  - ADD regex pattern caching for performance
  - OPTIMIZE bubble cleanup and memory management
  - PROFILE with Instruments for 60fps animation validation
```

### Per Task Pseudocode

```swift
// Task 5: VoiceCommandProcessor Core Implementation
@MainActor
class VoiceCommandProcessor: ObservableObject {
    @Published var activeBubbles: [CommandBubble] = []
    
    private let patternMatcher: PatternMatcher
    private let rcpGenerator: RCPCommandGenerator
    private let maxBubbles = 10
    private let bubbleLifetime: TimeInterval = 30.0
    
    // CRITICAL: Hook into existing SpeechRecognitionManager timer
    func processTranscription(_ text: String) {
        // Background processing without blocking UI
        Task.detached(priority: .background) { [weak self] in
            let commands = await self?.extractCommands(from: text) ?? []
            
            await MainActor.run {
                self?.updateBubbles(with: commands)
                self?.cleanupExpiredBubbles()
            }
        }
    }
    
    private func extractCommands(from text: String) async -> [RCPCommand] {
        // PATTERN: Mirror Python engine.py process_command structure
        let patterns = await patternMatcher.matchPatterns(in: text)
        var commands: [RCPCommand] = []
        
        for pattern in patterns {
            let rcp = await rcpGenerator.generateCommand(for: pattern)
            commands.append(rcp)
        }
        
        return commands.filter { $0.confidence >= 0.5 } // Confidence threshold
    }
}

// Task 7: CommandBubble UI Component
struct VoiceCommandBubble: View {
    let bubble: CommandBubble
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Human-readable description
            Text(bubble.rcpCommand.description)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Technical RCP command
            Text(bubble.rcpCommand.command)
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(.secondary)
            
            // Confidence indicator
            ConfidenceBar(confidence: bubble.rcpCommand.confidence)
        }
        .padding(12)
        .background(confidenceColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(confidenceColor.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // CRITICAL: Use iOS 17+ spring presets for hardware acceleration
            withAnimation(.bouncy(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private var confidenceColor: Color {
        // CRITICAL: Professional confidence color coding
        if bubble.rcpCommand.confidence >= 0.9 { return .green }
        else if bubble.rcpCommand.confidence >= 0.7 { return .orange } 
        else { return .red }
    }
}

// Task 9: Main UI Integration Pattern
// MODIFY VoiceControlMainView.swift body property
var body: some View {
    NavigationView {
        VStack(spacing: 20) {
            // PRESERVE existing header (lines 19-50)
            headerSection
            
            // NEW: 5:5 layout with side-by-side speech and bubbles
            HStack(spacing: 16) {
                // Left: Existing speech recognition (50%)
                VStack {
                    speechRecognitionSection
                    Spacer()
                    orbitalControlsSection
                }
                .frame(maxWidth: .infinity)
                
                // Right: New command bubbles (50%)
                VStack {
                    Text("Voice Commands")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    CommandBubblesView(manager: speechManager.commandBubbleManager)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            // PRESERVE existing status section (lines 134-152)
            statusSection
        }
    }
    // PRESERVE existing modifiers and lifecycle methods
}
```

### Integration Points

```yaml
SPEECHRECOGNITION:
  - hook: SpeechRecognitionManager.syncTranscriptionText() (line 295)
  - pattern: "commandProcessor.processTranscription(transcriptionText)"
  - timing: Every 100ms with existing timer sync

DEPENDENCIES:
  - add to: VoiceControlMainView.swift onAppear
  - pattern: "speechManager.configure(commandBubbleManager: CommandBubbleManager())"
  - injection: Follow existing AuthenticationManager pattern

UI_LAYOUT:
  - modify: VoiceControlMainView.swift body (lines 16-185)
  - pattern: "HStack with 50/50 split maintaining existing speech UI"
  - preserve: All existing orbital controls and status indicators

MEMORY:
  - implement: Automatic bubble cleanup after 30 seconds
  - pattern: "Timer-based cleanup with weak references"
  - limit: Maximum 10 concurrent bubbles in memory
```

## Validation Loop

### Level 1: Syntax & Style

```bash
# CRITICAL: Install SwiftLint first
brew install swiftlint

# Create .swiftlint.yml in project root with iOS best practices
# Run on all new Voice Command files
swiftlint lint VoiceControlApp/VoiceCommand/ --fix
swiftlint analyze VoiceControlApp/VoiceCommand/

# Expected: No errors. SwiftLint should report 0 violations.
# If errors: READ specific rule violation and fix code structure.
```

### Level 2: Unit Tests

```swift
// CREATE VoiceCommandTests/VoiceCommandProcessorTests.swift
@MainActor
class VoiceCommandProcessorTests: XCTestCase {
    var processor: VoiceCommandProcessor!
    
    override func setUp() {
        processor = VoiceCommandProcessor()
    }
    
    func testProfessionalTerminologyRecognition() {
        // Test high-confidence professional terms
        let result = processor.processCommand("crank channel 5")
        XCTAssertEqual(result.first?.confidence, 0.85, accuracy: 0.05)
        XCTAssertEqual(result.first?.category, .channelFader)
    }
    
    func testRCPCommandGeneration() {
        // Test RCP format correctness
        let result = processor.processCommand("set channel 1 to minus 6 dB")
        XCTAssertEqual(result.first?.command, "set MIXER:Current/InCh/Fader/Level 0 0 -600")
        XCTAssertEqual(result.first?.description, "Set channel 1 to -6.0 dB")
    }
    
    func testConfidenceScoring() {
        // Test confidence calculation accuracy
        let highConfidence = processor.processCommand("mute channel 3")
        let lowConfidence = processor.processCommand("make it louder")
        
        XCTAssertGreaterThan(highConfidence.first?.confidence ?? 0, 0.9)
        XCTAssertLessThan(lowConfidence.first?.confidence ?? 1, 0.6)
    }
}
```

```bash
# Run unit tests with iPhone 16 iOS 18.5 simulator
xcodebuild test -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5'

# Expected: All tests pass with ✓ status
# If failing: Use debugger to inspect command processing pipeline
```

### Level 3: Integration Test

```bash
# CRITICAL: Build and deploy to iPhone 16 iOS 18.5 simulator
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"
xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Launch the app on simulator
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Manual test: Speak professional audio commands
# Test commands: "crank channel 5", "mute the vocals", "set channel 1 to unity"
# Expected: Command bubbles appear within 500ms with correct RCP commands

# Capture logs for validation
tail -200 /Users/colinmignot/Library/Developer/CoreSimulator/Devices/5B1989A0-1EC8-4187-8A99-466B20CB58F2/data/Library/Logs/system.log | grep VoiceControlApp | head -30
```

### Level 4: Performance & Professional Audio Validation

```bash
# Performance validation with Instruments
xcrun xctrace record --template "Time Profiler" --launch -- /path/to/simulator/app
# Expected: 60fps during bubble animations, <50MB memory usage

# Professional audio terminology accuracy test
# Create test script with 100 professional audio commands
# Validate >90% recognition accuracy for standard mixing terms

# Real-time responsiveness test  
# Measure time from speech completion to bubble appearance
# Expected: <500ms latency for command bubble display

# Memory leak validation during extended use
# Run app for 30 minutes with continuous speech recognition
# Expected: Memory usage stabilizes, no unbounded growth
```

## Final Validation Checklist

- [ ] All unit tests pass: `xcodebuild test -project VoiceControlApp.xcodeproj`
- [ ] No SwiftLint violations: `swiftlint lint VoiceControlApp/VoiceCommand/`
- [ ] Manual test successful: Command bubbles appear <500ms after speech
- [ ] Professional terminology >90% accuracy for mixing console commands  
- [ ] Animation performance: Smooth 60fps bubble transitions
- [ ] Memory management: Automatic cleanup prevents unbounded growth
- [ ] Integration preserved: Existing speech recognition functionality intact
- [ ] iPhone 16 iOS 18.5 simulator compatibility confirmed

---

## Anti-Patterns to Avoid

- ❌ Don't use LazyVStack for real-time bubbles - List performs 23% better
- ❌ Don't block main thread with command processing - use Task.detached
- ❌ Don't hardcode professional terminology - use structured data from PRPs/ai_docs/
- ❌ Don't ignore confidence scoring - essential for professional audio accuracy
- ❌ Don't skip iPhone 16 iOS 18.5 simulator requirement - compatibility critical
- ❌ Don't modify existing speech recognition core - integrate non-invasively
- ❌ Don't use generic animations - leverage iOS 17+ hardware-accelerated presets
- ❌ Don't allow unbounded bubble growth - implement automatic cleanup

---

## Confidence Score: 9/10

This PRP provides comprehensive context for one-pass implementation success through:

✅ **Complete Professional Audio Context**: Full terminology database with confidence scoring
✅ **Detailed Architecture Integration**: Specific file patterns and existing code integration points  
✅ **Performance-Optimized Approach**: Research-backed SwiftUI best practices and animation patterns
✅ **Comprehensive Validation Strategy**: Multi-level testing from syntax to real-time performance
✅ **Professional-Grade Implementation**: Real-world audio engineering workflow support

The high confidence score reflects the extensive research, detailed implementation blueprints, and thorough validation gates that enable successful one-pass implementation by the AI agent.