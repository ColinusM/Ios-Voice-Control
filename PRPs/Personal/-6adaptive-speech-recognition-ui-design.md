# Adaptive Speech Recognition UI Design - Orbital Toggle System
name: "Adaptive Speech Recognition UI Design - Moon-Orbit Toggle PRP"
description: |
  Comprehensive PRP for implementing the orbital toggle UI system that allows users to seamlessly switch between AssemblyAI (professional accuracy) and iOS Speech Framework (ultra-low latency) in the iOS Voice Control app.

## Goal

Implement an intuitive "moon orbiting earth" UI pattern that allows users to switch between AssemblyAI (professional speech recognition) and iOS Speech Framework (fast speech recognition) engines while maintaining the current app's functionality and visual design language.

**End State**: A primary record button (earth) with a smaller orbital toggle button (moon) that rotates around it to switch between:
- **Professional Mode (AssemblyAI)**: Orange/amber button, superior noise handling, cloud processing
- **Fast Mode (iOS Speech)**: Blue button, ultra-low latency, on-device processing, offline capable

## Why

- **User Experience**: Provides choice between professional accuracy (mixing environments) and ultra-low latency (quiet environments)
- **Cost Optimization**: Allows users to use free iOS Speech when appropriate, reducing AssemblyAI usage costs
- **Environment Adaptation**: Smart recommendations based on detected audio conditions
- **Professional Workflow**: AssemblyAI remains default for professional mixing environments while offering speed boost option
- **Offline Capability**: iOS Speech works without internet connection for quiet environments

## What

### User-Visible Behavior
1. **Main Record Button (Earth)**: 80pt diameter button that maintains current recording functionality
2. **Orbital Toggle (Moon)**: 24pt diameter button that orbits at 60pt radius with two positions:
   - **0° (Top-right)**: Professional mode (AssemblyAI) - Orange color
   - **60° (Right side)**: Fast mode (iOS Speech) - Blue color
3. **Smooth Animations**: Spring-based transitions between orbital positions (0.6s duration)
4. **Color Transformation**: Main button changes color based on active engine
5. **Status Indicators**: Clear visual feedback showing which engine is active
6. **Smart Recommendations**: Gentle visual hints suggesting optimal engine for current environment

### Technical Requirements
1. **Engine Integration**: Seamless switching between AssemblyAI and iOS Speech Framework
2. **State Management**: Unified state coordination between both engines
3. **Audio Session Management**: Proper AVAudioSession handling during engine switches
4. **Environment Detection**: Real-time audio analysis for smart engine recommendations
5. **Memory Management**: Efficient resource cleanup during engine transitions
6. **Permission Handling**: Both engines require microphone access with proper fallbacks

### Success Criteria

- [ ] Orbital toggle button smoothly animates between two positions (0° and 60°)
- [ ] Main record button changes color based on active engine (orange/blue)
- [ ] AssemblyAI engine continues working exactly as before (no regression)
- [ ] iOS Speech Framework integration provides real-time transcription
- [ ] Engine switching works seamlessly without audio session conflicts
- [ ] Environment detection provides smart engine recommendations
- [ ] All animations feel native and smooth (60fps, spring-based)
- [ ] State management prevents data loss during engine switches
- [ ] Memory usage remains stable during engine transitions
- [ ] UI follows existing app design patterns and accessibility standards

## All Needed Context

### Documentation & References

```yaml
# MUST READ - Include these in your context window

- url: https://developer.apple.com/documentation/speech/sfspeechrecognizer
  why: Core iOS Speech Framework APIs, initialization patterns, real-time recognition
  critical: Rate limits (1000/hour server, no limits on-device), memory management

- url: https://developer.apple.com/documentation/speech/recognizing-speech-in-live-audio
  why: Real-time audio processing patterns, AVAudioEngine integration
  critical: Audio buffer handling, recognition request management

- url: https://developer.apple.com/videos/play/wwdc2023/10156/
  why: Advanced SwiftUI animations, keyframe animations, phase animations
  critical: Performance optimization for smooth orbital animations

- url: https://developer.apple.com/videos/play/wwdc2023/10157/
  why: SwiftUI spring animations, custom timing curves
  critical: Natural motion for orbital UI pattern

- file: VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift
  why: Current speech recognition implementation, state management patterns
  critical: WebSocket handling, error management, state synchronization

- file: VoiceControlApp/VoiceControlMainView.swift
  why: Current UI structure, button implementation, animation patterns
  critical: Integration point for orbital toggle (lines 105-122), existing state management

- file: VoiceControlApp/SpeechRecognition/AudioManager.swift
  why: Audio capture patterns, AVAudioEngine setup, permission handling
  critical: Audio session management, buffer processing, sample rate handling

- file: VoiceControlApp/Shared/Components/LoadingButton.swift
  why: App's button component patterns, styling enums, accessibility
  critical: Component architecture, enum-based styling, haptic feedback

- file: VoiceControlApp/Shared/Extensions/Color+Extensions.swift
  why: App color palette, theming system, dark mode support
  critical: Brand colors (.appPrimary, .appSecondary), dynamic color support

- file: VoiceControlApp/Shared/Utils/Constants.swift
  why: Animation timing constants, UI measurements, standardized values  
  critical: Animation.medium (0.3s), UI.CornerRadius, spacing constants

- url: https://github.com/amosgyamfi/open-swiftui-animations
  why: SwiftUI orbital animation examples, circular motion patterns
  critical: Polar coordinate conversion, rotationEffect animations

- url: https://iosexample.com/an-experiment-for-using-swiftuis-custom-timing-animation-to-create-an-orbital-like-animation/
  why: Specific orbital animation implementation in SwiftUI
  critical: Mathematical approach to circular motion, timing curves
```

### Current Codebase Tree

```bash
VoiceControlApp/
├── VoiceControlAppApp.swift                    # App entry point with Firebase config
├── ContentView.swift                           # Root view with auth flow
├── VoiceControlMainView.swift                  # Main app interface (INTEGRATION POINT)
├── AppDelegate.swift                           # iOS app lifecycle
├── Info.plist                                  # Permissions, URL schemes
├── GoogleService-Info.plist                    # Firebase configuration
├── VoiceControlApp.entitlements               # App capabilities
│
├── Authentication/                             # Complete auth system
│   ├── Components/
│   │   └── GoogleSignInButton.swift
│   ├── Models/
│   │   ├── AuthenticationError.swift
│   │   ├── AuthenticationState.swift
│   │   ├── GuestUser.swift
│   │   ├── SocialAuthError.swift
│   │   ├── SocialAuthResult.swift
│   │   └── User.swift
│   ├── Services/
│   │   ├── BiometricService.swift
│   │   ├── FirebaseAuthService.swift
│   │   ├── GoogleSignInService.swift
│   │   └── KeychainService.swift
│   ├── ViewModels/
│   │   ├── AuthenticationManager.swift         # STATE PATTERN REFERENCE
│   │   └── BiometricAuthManager.swift
│   └── Views/
│       ├── AccountManagementView.swift
│       ├── AuthenticationView.swift
│       ├── PasswordResetView.swift
│       ├── SignInView.swift
│       ├── SignUpView.swift
│       └── WelcomeView.swift
│
├── SpeechRecognition/                          # CORE INTEGRATION AREA
│   ├── AssemblyAIStreamer.swift               # Current speech engine (EXTEND)
│   ├── AudioManager.swift                     # Audio capture (EXTEND)
│   └── Models/
│       ├── StreamingConfig.swift              # Configuration patterns
│       └── TranscriptionModels.swift          # Data models, error handling
│
├── Shared/                                     # Reusable components
│   ├── Components/
│   │   ├── ErrorAlertModifier.swift
│   │   ├── LoadingButton.swift                # COMPONENT PATTERN REFERENCE
│   │   └── SecureTextField.swift
│   ├── Extensions/
│   │   ├── Color+Extensions.swift             # COLOR SYSTEM
│   │   └── View+Extensions.swift              # ANIMATION HELPERS
│   └── Utils/
│       ├── Constants.swift                    # ANIMATION/UI CONSTANTS
│       ├── NetworkMonitor.swift
│       └── Validation.swift
│
└── Subscriptions/                              # Usage tracking system
    ├── Models/
    │   ├── SubscriptionError.swift
    │   ├── SubscriptionPlan.swift
    │   └── SubscriptionState.swift
    ├── Services/
    │   └── StoreKitService.swift
    ├── ViewModels/
    │   └── SubscriptionManager.swift           # USAGE TRACKING PATTERN
    └── Views/
        ├── PlanCardView.swift
        └── SubscriptionView.swift
```

### Desired Codebase Tree with New Files

```bash
VoiceControlApp/
├── SpeechRecognition/                          # ENHANCED SPEECH SYSTEM
│   ├── AssemblyAIStreamer.swift               # EXISTING (modify to implement protocol)
│   ├── AudioManager.swift                     # EXISTING (extend for environment detection)
│   ├── IOSSpeechRecognizer.swift              # NEW - iOS Speech Framework integration
│   ├── SpeechRecognitionManager.swift         # NEW - Unified engine coordinator  
│   ├── EnvironmentAnalyzer.swift              # NEW - Smart recommendations
│   └── Models/
│       ├── StreamingConfig.swift              # EXISTING
│       ├── TranscriptionModels.swift          # EXISTING (extend with engine types)
│       ├── SpeechRecognitionProtocol.swift    # NEW - Common engine interface
│       └── EnvironmentModels.swift            # NEW - Audio environment detection
│
├── Shared/
│   └── Components/
│       ├── LoadingButton.swift                # EXISTING
│       ├── OrbitalToggleButton.swift          # NEW - Moon orbital toggle UI
│       └── RecordButton.swift                 # NEW - Enhanced earth record button
│
└── VoiceControlMainView.swift                  # MODIFIED - Integration point
```

### Known Gotchas of Codebase & Library Quirks

```swift
// CRITICAL: iOS Speech Framework Limitations
// - Server-based: 1000 requests/hour, 1-minute max per request
// - On-device: Requires iOS 13+ and A9+ processor for best performance
// - Memory leak: SFLocalSpeechRecognitionClient has known Framework-level leak

// CRITICAL: AVAudioSession Management 
// - Singleton pattern: Only one AVAudioSession per device
// - Cannot access microphone simultaneously from multiple engines
// - Must properly deactivate before switching between engines
// - Audio route changes (Bluetooth) can disrupt both engines

// CRITICAL: AssemblyAI WebSocket Patterns (from existing code)
// - Uses v3 API with URL query parameters (no session begin message)
// - Requires explicit connection timeout handling (max 3 retry attempts)
// - Binary audio data streaming at 16kHz, PCM_S16LE, mono
// - Connection state must be tracked for UI synchronization

// CRITICAL: Current App Architecture
// - MVVM pattern with ObservableObject and @Published properties
// - State synchronization: UI state (@State) syncs with engine state (@Published)
// - Dependency injection via @EnvironmentObject and manual configure() calls
// - Error handling through localized error enums and optional error messages

// CRITICAL: SwiftUI Animation Performance
// - Use .animation() modifier for simple state-driven animations
// - Use withAnimation for coordinated multi-view transitions  
// - Avoid continuous animations during audio processing (can cause stuttering)
// - Use @State for local animation properties (better performance than @Published)

// CRITICAL: Audio Processing Integration
// - Current downsampling: 44.1kHz/48kHz → 16kHz for AssemblyAI
// - Buffer size: 1024 samples for low latency (existing pattern)
// - Format conversion: Float32 → Int16 for AssemblyAI compatibility
// - iOS Speech can work with native format (no conversion needed)

// CRITICAL: Permissions & Privacy
// - Microphone: Both engines need NSMicrophoneUsageDescription
// - Speech Recognition: iOS Speech needs NSSpeechRecognitionUsageDescription  
// - Both permissions must be granted before engine can start
// - Handle permission denial gracefully with clear user feedback
```

## Implementation Blueprint

### Data Models and Structure

Create the core data models to ensure type safety and engine coordination.

```swift
// NEW: SpeechRecognitionProtocol.swift
protocol SpeechRecognitionEngine: ObservableObject {
    var isStreaming: Bool { get }
    var transcriptionText: String { get }
    var connectionState: StreamingState { get }
    var errorMessage: String? { get }
    
    func startStreaming() async
    func stopStreaming()
    func clearTranscriptionText()
    func configure(subscriptionManager: SubscriptionManager, authManager: AuthenticationManager)
}

// NEW: Enhanced TranscriptionModels.swift additions
enum SpeechRecognitionMode: String, CaseIterable {
    case professional = "professional"  // AssemblyAI
    case fast = "fast"                  // iOS Speech
    
    var displayName: String {
        switch self {
        case .professional: return "Pro Accuracy"
        case .fast: return "Fast & Free"
        }
    }
    
    var color: Color {
        switch self {
        case .professional: return .orange
        case .fast: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .professional: return "cloud.fill"
        case .fast: return "waveform"
        }
    }
    
    var orbitalAngle: Double {
        switch self {
        case .professional: return 0.0    // Top-right position
        case .fast: return 60.0           // Right side position
        }
    }
}

// NEW: EnvironmentModels.swift
struct EnvironmentMeasurement {
    let noiseLevel: Float              // dB level
    let musicDetected: Bool            // Background music present
    let multipleSpeakers: Bool         // Multiple voices detected
    let speechClarity: Float           // 0.0-1.0 clarity score
    let frequencyComplexity: Float     // 0.0-1.0 complexity score
    let timestamp: Date
    
    var categoryKey: String {
        // Generate key for user preference learning
        return "\(Int(noiseLevel/5)*5)_\(musicDetected)_\(multipleSpeakers)"
    }
}

enum NoiseCategory {
    case veryQuiet, quiet, moderate, loud, veryLoud
    
    var recommendedEngine: SpeechRecognitionMode {
        switch self {
        case .veryQuiet, .quiet: return .fast
        default: return .professional
        }
    }
}
```

### List of Tasks to be Completed (In Order)

```yaml
Task 1 - iOS Speech Framework Integration:
CREATE VoiceControlApp/SpeechRecognition/IOSSpeechRecognizer.swift:
  - IMPLEMENT SpeechRecognitionEngine protocol
  - MIRROR state management pattern from AssemblyAIStreamer.swift
  - USE SFSpeechRecognizer with real-time audio buffer recognition
  - HANDLE permissions: microphone + speech recognition
  - PRESERVE existing error handling patterns from TranscriptionModels.swift
  - INTEGRATE with existing AudioManager for audio capture

Task 2 - Unified Speech Engine Manager:
CREATE VoiceControlApp/SpeechRecognition/SpeechRecognitionManager.swift:
  - COORDINATE between AssemblyAIStreamer and IOSSpeechRecognizer
  - IMPLEMENT engine switching with proper cleanup
  - BIND engine states to unified @Published properties
  - HANDLE engine switching without audio session conflicts
  - PRESERVE transcription continuity during switches
  - INTEGRATE with existing dependency injection pattern

Task 3 - Environment Detection System:
CREATE VoiceControlApp/SpeechRecognition/EnvironmentAnalyzer.swift:
  - EXTEND AudioManager's audio processing for environment detection
  - IMPLEMENT real-time noise level measurement (dB calculation)
  - ADD background music detection using FFT analysis
  - CREATE multiple speaker detection via zero-crossing rate
  - GENERATE smart engine recommendations with hysteresis
  - OPTIMIZE for battery efficiency (2Hz analysis vs 10Hz audio)

Task 4 - Protocol Implementation Updates:
MODIFY VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - IMPLEMENT SpeechRecognitionEngine protocol
  - PRESERVE all existing functionality and state management
  - MAINTAIN WebSocket connection patterns
  - KEEP current error handling and retry logic
  - ENSURE no breaking changes to existing integration

CREATE VoiceControlApp/SpeechRecognition/Models/SpeechRecognitionProtocol.swift:
  - DEFINE common interface for all engine types
  - MATCH existing AssemblyAIStreamer method signatures
  - INCLUDE async/await patterns for engine operations
  - SUPPORT dependency injection configuration

Task 5 - Orbital Toggle UI Component:
CREATE VoiceControlApp/Shared/Components/OrbitalToggleButton.swift:
  - IMPLEMENT moon button orbiting at 60pt radius
  - CREATE smooth spring animations between 0° and 60° positions
  - SUPPORT gesture handling: tap, long-press, drag
  - INTEGRATE haptic feedback using existing patterns
  - FOLLOW LoadingButton.swift component architecture
  - USE app color palette from Color+Extensions.swift

Task 6 - Enhanced Record Button:
CREATE VoiceControlApp/Shared/Components/RecordButton.swift:
  - EXTRACT current record button from VoiceControlMainView.swift (lines 105-122)
  - ENHANCE with engine-specific color transformations
  - ADD smooth color transitions between orange/blue
  - MAINTAIN existing scale animations and shadow effects
  - INTEGRATE with SpeechRecognitionMode enum for styling

Task 7 - Main View Integration:
MODIFY VoiceControlApp/VoiceControlMainView.swift:
  - REPLACE @StateObject assemblyAIStreamer with unified SpeechRecognitionManager
  - INTEGRATE OrbitalToggleButton and RecordButton components (lines 105-122)
  - ADD environment detection notification handling
  - IMPLEMENT engine switching user actions
  - PRESERVE all existing authentication and subscription integration
  - MAINTAIN current layout and spacing patterns

Task 8 - Environment Models & Extensions:
CREATE VoiceControlApp/SpeechRecognition/Models/EnvironmentModels.swift:
  - DEFINE EnvironmentMeasurement struct with audio metrics
  - CREATE NoiseCategory enum with engine recommendations
  - ADD user preference learning data structures
  - INCLUDE mathematical functions for audio analysis

MODIFY VoiceControlApp/SpeechRecognition/AudioManager.swift:
  - EXTEND existing installTap for environment analysis
  - ADD dB level calculation from audio buffers
  - INTEGRATE FFT analysis for music/speech detection
  - PRESERVE existing audio capture and streaming functionality

Task 9 - Smart Recommendation System:
ENHANCE VoiceControlApp/SpeechRecognition/EnvironmentAnalyzer.swift:
  - IMPLEMENT real-time recommendation engine
  - ADD hysteresis to prevent rapid engine switching
  - CREATE user preference learning and storage
  - INTEGRATE with NotificationCenter for UI updates
  - BALANCE analysis frequency for battery efficiency

Task 10 - Integration Testing & Validation:
VALIDATE VoiceControlMainView.swift integration:
  - ENSURE smooth engine switching without audio interruption
  - VERIFY transcription continuity during switches
  - TEST environment recommendations in various conditions
  - CONFIRM memory management during engine transitions
  - VALIDATE UI animations perform at 60fps
```

### Per Task Pseudocode with Critical Details

```swift
// Task 1: IOSSpeechRecognizer.swift
class IOSSpeechRecognizer: NSObject, SpeechRecognitionEngine, ObservableObject {
    @Published var isStreaming: Bool = false
    @Published var transcriptionText: String = ""
    @Published var connectionState: StreamingState = .disconnected
    @Published var errorMessage: String? = nil
    
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startStreaming() async {
        // PATTERN: Permission checking first (mirror AudioManager pattern)
        guard await requestPermissions() else { 
            errorMessage = "Permissions required"
            return 
        }
        
        // PATTERN: Audio session configuration (existing pattern from AudioManager)
        try configureAudioSession()
        
        // CRITICAL: iOS Speech requires recognition request setup
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = true  // For offline use
        
        // PATTERN: Audio engine tap (mirror existing AudioManager installTap)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // CRITICAL: Recognition task with result handling
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            await MainActor.run {  // PATTERN: UI updates on main thread
                if let result = result {
                    self.transcriptionText = result.bestTranscription.formattedString
                }
                if let error = error {
                    self.handleError(error)
                }
            }
        }
        
        // PATTERN: Start audio engine (existing pattern)
        audioEngine.prepare()
        try audioEngine.start()
        
        await MainActor.run {
            self.isStreaming = true
            self.connectionState = .connected
        }
    }
    
    // CRITICAL: Proper cleanup to prevent memory leaks
    func stopStreaming() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)  // MUST remove tap
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        
        // PATTERN: Clear references (prevent leaks)
        recognitionTask = nil
        recognitionRequest = nil
        
        isStreaming = false
        connectionState = .disconnected
    }
}

// Task 2: SpeechRecognitionManager.swift
class SpeechRecognitionManager: ObservableObject {
    @Published var activeEngine: SpeechRecognitionMode = .professional
    @Published var isRecording: Bool = false
    @Published var transcriptionText: String = ""
    @Published var connectionState: StreamingState = .disconnected
    @Published var errorMessage: String?
    
    private let assemblyAIEngine: AssemblyAIStreamer
    private let appleSpeechEngine: IOSSpeechRecognizer
    private var cancellables = Set<AnyCancellable>()
    
    private var currentEngine: SpeechRecognitionEngine {
        return activeEngine == .professional ? assemblyAIEngine : appleSpeechEngine
    }
    
    func switchEngine(to newEngine: SpeechRecognitionMode) async {
        // CRITICAL: Stop current engine cleanly
        if isRecording {
            await currentEngine.stopStreaming()
        }
        
        // PATTERN: State preservation during switch
        let preservedText = transcriptionText
        
        await MainActor.run {
            activeEngine = newEngine
        }
        
        // PATTERN: Bind to new engine's state
        bindToActiveEngine()
        
        // CRITICAL: Restore state if switching mid-session
        if isRecording {
            await currentEngine.startStreaming()
            // Preserve accumulated transcription
            transcriptionText = preservedText + currentEngine.transcriptionText
        }
    }
    
    private func bindToActiveEngine() {
        cancellables.removeAll()
        
        // PATTERN: Combine publisher binding (efficient state sync)
        currentEngine.$isStreaming
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)
        
        currentEngine.$transcriptionText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcriptionText)
        
        currentEngine.$connectionState
            .receive(on: DispatchQueue.main)  
            .assign(to: &$connectionState)
        
        currentEngine.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}

// Task 5: OrbitalToggleButton.swift  
struct OrbitalToggleButton: View {
    let angle: Double
    let currentMode: SpeechRecognitionMode
    let onToggle: (SpeechRecognitionMode) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isPressed = false
    
    private let orbitRadius: CGFloat = 60
    private let moonSize: CGFloat = 24
    
    var body: some View {
        ZStack {
            // PATTERN: Orbit path indicator (subtle UI guidance)
            Circle()
                .stroke(currentMode.color.opacity(0.3), lineWidth: 1)
                .frame(width: orbitRadius * 2, height: orbitRadius * 2)
            
            // PATTERN: Moon button positioned via polar coordinates
            Button(action: { toggleMode() }) {
                ZStack {
                    Circle()
                        .fill(currentMode.color)
                        .frame(width: moonSize, height: moonSize)
                        .shadow(radius: isPressed ? 6 : 3)
                    
                    Image(systemName: currentMode.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 1.2 : 1.0)
            .offset(polarToCartesian(angle: angle, radius: orbitRadius))
            .offset(dragOffset)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: angle)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .gesture(
                DragGesture()
                    .onChanged { handleDrag($0) }
                    .onEnded { _ in handleDragEnd() }
            )
        }
    }
    
    private func polarToCartesian(angle: Double, radius: CGFloat) -> CGSize {
        let radians = angle * .pi / 180
        return CGSize(
            width: radius * cos(radians),
            height: radius * sin(radians)
        )
    }
    
    private func toggleMode() {
        // PATTERN: Haptic feedback (existing app pattern)
        HapticManager.mediumImpact()
        
        let newMode: SpeechRecognitionMode = currentMode == .professional ? .fast : .professional
        onToggle(newMode)
    }
}

// Task 7: VoiceControlMainView.swift Integration
struct VoiceControlMainView: View {
    @StateObject private var speechManager = SpeechRecognitionManager()  // REPLACE assemblyAIStreamer
    @State private var orbitalAngle: Double = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // ... existing header content ...
            
            // REPLACE: Lines 105-122 (current microphone button)
            ZStack {
                // Main Record Button (Earth)
                RecordButton(
                    isRecording: speechManager.isRecording,
                    mode: speechManager.activeEngine,
                    onTap: { toggleRecording() }
                )
                
                // Orbital Toggle (Moon)
                OrbitalToggleButton(
                    angle: orbitalAngle,
                    currentMode: speechManager.activeEngine,
                    onToggle: { newMode in
                        Task {
                            await switchToEngine(newMode)
                        }
                    }
                )
            }
            .frame(height: 160)  // Accommodate orbital radius
            
            // ... existing status and controls ...
        }
        .onReceive(NotificationCenter.default.publisher(for: .engineRecommendationUpdated)) { notification in
            handleEnvironmentRecommendation(notification)
        }
        .onAppear {
            // PATTERN: Dependency injection (existing pattern)
            speechManager.configure(
                subscriptionManager: subscriptionManager,
                authManager: authManager
            )
            
            // Initialize orbital position
            orbitalAngle = speechManager.activeEngine.orbitalAngle
        }
    }
    
    private func switchToEngine(_ newEngine: SpeechRecognitionMode) async {
        // PATTERN: Coordinated animation with state change
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            orbitalAngle = newEngine.orbitalAngle
        }
        
        await speechManager.switchEngine(to: newEngine)
    }
}
```

### Integration Points

```yaml
AUDIO SESSION:
  - coordinate: "Single AVAudioSession shared between engines"
  - pattern: "Proper deactivation before engine switch"
  - configuration: "Category: .playAndRecord, Mode: .measurement"

PERMISSIONS:
  - microphone: "Both engines require NSMicrophoneUsageDescription"  
  - speech: "iOS Speech requires NSSpeechRecognitionUsageDescription"
  - handling: "Graceful fallback with user guidance on denial"

STATE MANAGEMENT:
  - replace: "VoiceControlMainView @StateObject assemblyAIStreamer"
  - with: "VoiceControlMainView @StateObject speechManager"
  - preserve: "All existing authentication and subscription integration"

UI COMPONENTS:
  - location: "VoiceControlMainView.swift lines 105-122"
  - replace: "Current microphone button implementation"  
  - maintain: "Existing spacing, animation timing, haptic feedback patterns"

ENVIRONMENT DETECTION:
  - integrate: "AudioManager installTap for real-time analysis"
  - notify: "NotificationCenter for UI recommendation updates"
  - optimize: "2Hz analysis frequency for battery efficiency"

DEPENDENCY INJECTION:
  - pattern: "Follow existing configure() method pattern"
  - services: "SubscriptionManager, AuthenticationManager injection"
  - environment: "@EnvironmentObject pattern for child views"
```

## Validation Loop

### Level 1: Syntax & Swift Compilation

```bash
# Run these FIRST - fix any errors before proceeding
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng

# Build project to verify syntax
xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Expected: Build succeeds. If errors, READ the error and fix syntax/imports.
```

### Level 2: Component Unit Testing

```swift
// TEST in VoiceControlMainView.swift - Manual verification
// 1. Orbital Toggle Component Test
func testOrbitalToggleAnimation() {
    // VERIFY: Moon button smoothly animates between 0° and 60° positions
    // VERIFY: Spring animation duration matches design (0.6s)  
    // VERIFY: Button scales on press (1.0 → 1.2 → 1.0)
    // VERIFY: Colors change based on active engine (orange/blue)
}

// 2. Engine Switching Test  
func testEngineSwitching() {
    // VERIFY: AssemblyAI → iOS Speech switch works without audio session conflict
    // VERIFY: iOS Speech → AssemblyAI switch works without transcription loss
    // VERIFY: Mid-recording switches preserve accumulated text
    // VERIFY: Engine switching completes within 200ms
}

// 3. Permission Handling Test
func testPermissionFallbacks() {
    // VERIFY: Microphone permission denial shows appropriate error
    // VERIFY: Speech recognition permission denial handled gracefully
    // VERIFY: Both engines degrade properly when permissions unavailable
}
```

```bash
# iOS Simulator Testing (Manual)
cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build

# Then launch app on simulator
xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app

# Expected: App launches, orbital toggle visible, engines switch smoothly
# If failing: Check simulator logs for specific error messages
```

### Level 3: Real-time Integration Testing

```bash
# Environment Detection Test
# 1. Start app in iPhone 16 iOS 18.5 simulator
# 2. Test in quiet environment (should recommend iOS Speech - blue glow)
# 3. Play background music (should recommend AssemblyAI - orange glow)
# 4. Verify recommendations don't switch rapidly (hysteresis working)

# Engine Performance Test
# 1. Record 30-second sample with AssemblyAI engine
# 2. Switch to iOS Speech engine mid-recording
# 3. Verify transcription continuity (no text loss)
# 4. Check memory usage stability during switch

# UI Animation Performance Test  
# 1. Switch engines rapidly multiple times
# 2. Verify 60fps performance during orbital animations
# 3. Check for animation stuttering during audio processing
# 4. Verify haptic feedback triggers appropriately

# Expected Results:
# - Engine switching: <200ms latency
# - Animation performance: Smooth 60fps
# - Memory usage: Stable during transitions
# - Transcription continuity: No text loss during switches
```

### Level 4: Production Environment Validation

```bash
# Battery Impact Analysis
# - Monitor battery usage during 30-minute session with engine switching
# - Expected: <10% additional drain compared to single-engine usage

# Audio Quality Validation
# - Test both engines in studio mixing environment
# - Verify AssemblyAI maintains superior accuracy in noisy conditions
# - Verify iOS Speech provides ultra-low latency in quiet conditions

# Edge Case Testing
# - Test engine switching during network interruption (AssemblyAI)
# - Test iOS Speech behavior when device storage low
# - Test permission revocation during active recording
# - Test audio route changes (Bluetooth headphones) during engine switch

# Performance Benchmarking
# - Measure engine switch latency (target: <100ms)
# - Measure transcription accuracy in various noise conditions
# - Measure memory usage stability over 1-hour session
# - Measure UI responsiveness during continuous engine switching
```

## Final Validation Checklist

- [ ] Build succeeds: `xcodebuild -project VoiceControlApp.xcodeproj -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 16 18.5,OS=18.5' -configuration Debug build`
- [ ] Orbital toggle animates smoothly between 0° and 60° positions
- [ ] Main record button changes color based on active engine (orange/blue)
- [ ] AssemblyAI engine continues working exactly as before (no regression)
- [ ] iOS Speech Framework provides real-time transcription
- [ ] Engine switching works without audio session conflicts (<200ms latency)
- [ ] Environment detection provides smart recommendations with gentle UI hints
- [ ] Memory usage remains stable during engine transitions
- [ ] All animations perform at 60fps during audio processing
- [ ] Transcription continuity preserved during mid-recording engine switches
- [ ] Permission handling provides graceful fallbacks and clear user guidance
- [ ] UI follows existing app design patterns and accessibility standards
- [ ] App launches successfully on iPhone 16 iOS 18.5 simulator: `xcrun simctl launch 5B1989A0-1EC8-4187-8A99-466B20CB58F2 com.voicecontrol.app`

---

## Anti-Patterns to Avoid

- ❌ Don't create new state management patterns when existing ObservableObject/@Published works
- ❌ Don't skip proper AVAudioSession cleanup - will cause audio conflicts
- ❌ Don't use continuous orbital animations during audio processing - causes stuttering
- ❌ Don't ignore iOS Speech Framework rate limits - implement proper on-device fallback
- ❌ Don't break existing AssemblyAI functionality - maintain backward compatibility  
- ❌ Don't use @Published for local animation properties - use @State for better performance
- ❌ Don't forget to remove audio taps before installing new ones - causes memory leaks
- ❌ Don't switch engines without proper user feedback - provide visual confirmation
- ❌ Don't hardcode orbital positions - use calculated polar coordinates for accuracy
- ❌ Don't implement engine switching without hysteresis - prevents rapid switching
- ❌ Don't ignore permission denial scenarios - provide clear user guidance

---

## Quality Score: 9/10

**Confidence Level for One-Pass Implementation Success**: This PRP provides comprehensive context including:
- Complete current codebase architecture analysis
- Detailed iOS Speech Framework integration patterns  
- Specific mathematical approaches for orbital UI animations
- Existing app design patterns and component architecture
- Environment detection algorithms with performance optimizations
- Extensive error handling and edge case coverage
- Clear validation gates with executable tests
- Anti-patterns based on research findings

The PRP enables an AI agent to implement the feature successfully through iterative refinement with minimal external dependencies.