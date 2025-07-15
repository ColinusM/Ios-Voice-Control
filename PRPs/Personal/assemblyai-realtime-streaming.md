name: "AssemblyAI Real-Time Speech-to-Text Streaming Integration"
description: |
  Integrate AssemblyAI's real-time streaming WebSocket API into the iOS Voice Control app to replace placeholder speech recognition with live transcription that populates the text box in real-time.

---

## Goal

Replace the placeholder speech recognition functionality in VoiceControlMainView with AssemblyAI's real-time streaming speech-to-text service. When the user taps the microphone button, the app should capture audio from the microphone, stream it to AssemblyAI's WebSocket endpoint, and display transcribed text in real-time in the existing text box.

## Why

- **Real Speech Recognition**: Replace dummy text with actual speech-to-text functionality
- **User Experience**: Provide immediate visual feedback as speech is transcribed
- **Enterprise-grade**: AssemblyAI offers production-ready speech recognition with high accuracy
- **Integration Ready**: Existing UI already has text display and recording state management
- **Professional**: Move from prototype to functional voice control application

## What

Real-time bidirectional speech streaming where:
1. User taps microphone button to start recording
2. App captures audio from microphone using AVAudioEngine
3. Audio is streamed in real-time to AssemblyAI WebSocket API 
4. Transcribed text appears immediately in the existing text box
5. User can stop recording by tapping microphone button again
6. All existing UI states and animations are preserved

### Success Criteria

- [ ] Microphone button starts/stops real audio recording (not placeholder)
- [ ] Live audio is captured and streamed to AssemblyAI WebSocket
- [ ] Transcribed text appears in real-time in the speechText field
- [ ] Text accumulates during recording session
- [ ] Recording state visually indicates active transcription
- [ ] Proper error handling for network/audio failures
- [ ] Microphone permissions are properly requested and handled
- [ ] Works on physical iPhone device (as required by CLAUDE.md)

## All Needed Context

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- url: https://assemblyai.com/docs/speech-to-text/streaming
  why: Primary API documentation for WebSocket streaming protocol

- url: https://www.assemblyai.com/docs/api-reference/streaming-api/streaming-api  
  why: Complete WebSocket message format and authentication details

- url: https://www.assemblyai.com/docs/api-reference/streaming/create-temporary-token
  why: Authentication via temporary tokens (required security pattern)

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/VoiceControlMainView.swift
  why: Target file with existing UI and placeholder toggleRecording() function

- file: /Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng/VoiceControlApp/ContentView.swift
  why: Main app structure with AuthenticationManager patterns to follow

- url: https://github.com/daltoniam/Starscream
  why: WebSocket library for iOS that supports binary data streaming

- url: https://developer.apple.com/documentation/avfaudio/avaudioengine
  why: iOS audio capture API for real-time microphone access

- url: https://arvindhsukumar.medium.com/using-avaudioengine-to-record-compress-and-stream-audio-on-ios-48dfee09fde4
  why: Implementation patterns for AVAudioEngine real-time streaming

- doc: AssemblyAI WebSocket Endpoint
  endpoint: wss://streaming.assemblyai.com/v3/ws
  critical: Requires temporary token authentication, PCM16 audio at 16kHz+
```

### Current Codebase Structure

```bash
VoiceControlApp/
├── VoiceControlAppApp.swift              # Main app entry with Firebase setup
├── ContentView.swift                     # Authentication flow and app structure  
├── VoiceControlMainView.swift            # 🎯 TARGET: Contains speechText state and toggleRecording()
├── Info.plist                           # Need to add microphone permission
├── GoogleService-Info.plist              # Firebase config (existing)
└── Authentication/                       # Existing auth modules (reference patterns)

Current Dependencies (project.pbxproj):
- Firebase (Auth, Database, Firestore, Functions)
- GoogleSignIn & GoogleSignInSwift
- InjectionNext (dev hot reloading)
- HotSwiftUI (dev)
```

### Desired Codebase Structure with New Files

```bash
VoiceControlApp/
├── VoiceControlMainView.swift            # MODIFY: Replace toggleRecording() with real implementation
├── SpeechRecognition/                    # NEW: Speech-to-text module
│   ├── AssemblyAIStreamer.swift         # CORE: WebSocket + audio streaming orchestrator
│   ├── AudioManager.swift               # NEW: AVAudioEngine wrapper for mic capture
│   └── Models/                          # NEW: Data models
│       ├── StreamingConfig.swift        # AssemblyAI configuration
│       └── TranscriptionModels.swift    # Response/error models
├── Info.plist                          # MODIFY: Add NSMicrophoneUsageDescription
└── VoiceControlApp.xcodeproj            # MODIFY: Add Starscream WebSocket dependency
```

### Known Gotchas & Critical Requirements

```swift
// CRITICAL: AssemblyAI Requirements
// - No official iOS SDK - must implement WebSocket protocol directly
// - WebSocket endpoint: wss://streaming.assemblyai.com/v3/ws
// - Audio format: PCM16, 16000+ Hz sample rate, single channel, 50ms chunks optimal
// - Authentication: Temporary tokens only (generated server-side, 60-360000s expiration)
// - Each token is single-use only

// CRITICAL: iOS Audio Gotchas  
// - Use AVAudioEngine (NOT AVAudioRecorder) for real-time streaming
// - installTap() must be called BEFORE starting engine
// - Audio session must be configured for .playAndRecord category
// - Microphone permissions required in Info.plist
// - Background audio needs UIBackgroundModes in Info.plist

// CRITICAL: WebSocket Implementation
// - AssemblyAI expects binary audio data, not base64
// - Connection must send authentication message first
// - Partial transcripts come before final transcripts
// - Must handle connection drops and retry logic

// CRITICAL: CLAUDE.md Requirements
// - MUST test on physical iPhone device only (never simulator)
// - Use fast build command for testing: ios-deploy -b ...app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14
```

## Implementation Blueprint

### Data Models and Structure

```swift
// Core configuration and response models for type safety and consistency

// MIRROR pattern from existing AuthenticationManager in ContentView.swift
class AssemblyAIStreamer: ObservableObject {
    @Published var isStreaming: Bool = false
    @Published var transcriptionText: String = ""
    @Published var errorMessage: String?
}

// Configuration following Firebase patterns in existing codebase
struct StreamingConfig {
    let apiKey: String  // For server-side token generation
    let sampleRate: Int = 16000
    let encoding: String = "pcm_s16le" 
    let language: String = "en"
}

// Response models matching AssemblyAI WebSocket protocol
struct TranscriptionResponse: Codable {
    let message_type: String  // "PartialTranscript" or "FinalTranscript"
    let text: String
    let confidence: Double?
    let words: [Word]?
}
```

### List of Tasks in Implementation Order

```yaml
Task 1:
MODIFY VoiceControlApp.xcodeproj:
  - ADD Starscream WebSocket library via Swift Package Manager
  - URL: https://github.com/daltoniam/Starscream.git
  - VERSION: 4.0.6 or latest stable

Task 2:  
MODIFY VoiceControlApp/Info.plist:
  - ADD NSMicrophoneUsageDescription key
  - VALUE: "This app needs microphone access for real-time speech recognition."
  - PATTERN: Similar to existing GoogleService-Info.plist configuration

Task 3:
CREATE VoiceControlApp/SpeechRecognition/Models/StreamingConfig.swift:
  - FOLLOW pattern from: VoiceControlApp/Authentication/Models/User.swift
  - CREATE configuration struct for AssemblyAI settings
  - INCLUDE sample rate, encoding, endpoint URL constants

Task 4:
CREATE VoiceControlApp/SpeechRecognition/Models/TranscriptionModels.swift:
  - FOLLOW pattern from: VoiceControlApp/Authentication/Models/AuthenticationState.swift
  - CREATE Codable structs for AssemblyAI WebSocket responses
  - HANDLE both partial and final transcript message types

Task 5:
CREATE VoiceControlApp/SpeechRecognition/AudioManager.swift:
  - ENCAPSULATE AVAudioEngine setup and audio capture
  - MIRROR error handling pattern from: AuthenticationManager in ContentView.swift
  - CONFIGURE PCM16 format at 16kHz for AssemblyAI compatibility
  - IMPLEMENT audio buffer callback for real-time streaming

Task 6:
CREATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - COMBINE WebSocket communication + AudioManager orchestration
  - MIRROR ObservableObject pattern from: AuthenticationManager
  - IMPLEMENT temporary token authentication flow
  - HANDLE real-time audio streaming to WebSocket
  - PROCESS incoming transcription responses

Task 7:
MODIFY VoiceControlApp/VoiceControlMainView.swift:
  - REPLACE toggleRecording() implementation with AssemblyAIStreamer integration
  - PRESERVE existing UI components and animations  
  - BIND speechText to AssemblyAIStreamer.transcriptionText
  - MAINTAIN isRecording state synchronization
```

### Per Task Pseudocode

```swift
// Task 5: AudioManager.swift - Critical audio capture implementation
class AudioManager {
    private var audioEngine: AVAudioEngine!
    private var audioCallback: ((Data) -> Void)?
    
    func startRecording(callback: @escaping (Data) -> Void) {
        // PATTERN: Request permissions first (see existing auth patterns)
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { 
                // CRITICAL: Handle permission denial gracefully
                self.errorHandler("Microphone permission denied")
                return 
            }
            
            // CRITICAL: Configure audio session for real-time capture
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // PATTERN: Audio format for AssemblyAI (PCM16, 16kHz, mono)
            let format = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                     sampleRate: 16000, channels: 1, interleaved: true)!
            
            // CRITICAL: Install tap BEFORE starting engine
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
                // GOTCHA: Convert AVAudioPCMBuffer to Data for WebSocket
                let data = self.convertBufferToData(buffer)
                callback(data)
            }
            
            try audioEngine.start()
        }
    }
}

// Task 6: AssemblyAIStreamer.swift - WebSocket orchestration  
class AssemblyAIStreamer: ObservableObject {
    @Published var transcriptionText: String = ""
    private var webSocket: WebSocket!
    private var audioManager = AudioManager()
    
    func startStreaming() {
        // PATTERN: Async error handling like AuthenticationManager.signInWithGoogle()
        Task {
            do {
                // CRITICAL: Get temporary token from server (not hardcoded API key)
                let token = try await getTemporaryToken()
                
                // PATTERN: WebSocket setup with error delegate pattern
                var request = URLRequest(url: URL(string: "wss://streaming.assemblyai.com/v3/ws")!)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                webSocket = WebSocket(request: request)
                webSocket.delegate = self
                webSocket.connect()
                
                // CRITICAL: Start audio capture only after WebSocket connects
                audioManager.startRecording { audioData in
                    self.webSocket.write(data: audioData)
                }
                
            } catch {
                // PATTERN: Error handling like existing AuthenticationManager
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// Task 7: VoiceControlMainView.swift integration
private func toggleRecording() {
    if isRecording {
        // Stop streaming
        assemblyAIStreamer.stopStreaming()
        isRecording = false
    } else {
        // Start streaming  
        assemblyAIStreamer.startStreaming()
        isRecording = true
    }
}
```

### Integration Points

```yaml
DEPENDENCIES:
  - add: Starscream WebSocket library to VoiceControlApp.xcodeproj
  - version: 4.0.6+ (latest stable)
  - method: Swift Package Manager

PERMISSIONS:
  - add to: VoiceControlApp/Info.plist
  - key: NSMicrophoneUsageDescription
  - pattern: "This app needs microphone access for real-time speech recognition."

UI_INTEGRATION:
  - modify: VoiceControlMainView.swift speechText binding
  - pattern: "@State private var speechText" becomes "@StateObject private var assemblyAIStreamer"
  - preserve: All existing UI animations and recording state indicators

AUTHENTICATION:
  - extend: Existing Firebase/Google auth patterns
  - add: Server-side AssemblyAI temporary token generation endpoint
  - security: Never expose AssemblyAI API key in iOS app
```

## Validation Loop

### Level 1: Syntax & Style (Use Existing iOS Validation)

```bash
# iOS projects don't use ruff/mypy - use Xcode's built-in validation
# Build the project to check for Swift syntax errors
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"

# MANDATORY: Use physical device build from CLAUDE.md
time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14

# Expected: Clean build with no Swift compiler errors
# If errors: Read Xcode output, fix Swift syntax/type issues, rebuild
```

### Level 2: Unit Tests (Follow iOS Testing Patterns)

```swift
// CREATE VoiceControlAppTests/AssemblyAIStreamerTests.swift
// FOLLOW existing iOS testing patterns (if any exist in project)

import XCTest
@testable import VoiceControlApp

class AssemblyAIStreamerTests: XCTestCase {
    
    func testAudioManagerPermissions() {
        // Test microphone permission handling
        let audioManager = AudioManager()
        let expectation = XCTestExpectation(description: "Permission handled")
        
        audioManager.requestPermissions { granted in
            // Should handle both granted and denied cases gracefully
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testWebSocketConnection() {
        // Test WebSocket connection with mock token
        let streamer = AssemblyAIStreamer()
        
        // Mock successful connection scenario
        // Verify state changes correctly (isStreaming = true)
        XCTAssertFalse(streamer.isStreaming)
    }
    
    func testTranscriptionResponseParsing() {
        // Test JSON response parsing from AssemblyAI
        let jsonData = """
        {
            "message_type": "PartialTranscript",
            "text": "Hello world",
            "confidence": 0.95
        }
        """.data(using: .utf8)!
        
        let response = try! JSONDecoder().decode(TranscriptionResponse.self, from: jsonData)
        XCTAssertEqual(response.text, "Hello world")
        XCTAssertEqual(response.message_type, "PartialTranscript")
    }
}
```

```bash
# Run iOS unit tests via Xcode command line tools
xcodebuild test -scheme VoiceControlApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Expected: All tests pass
# If failing: Read test output, fix implementation, re-run
```

### Level 3: Integration Test (Physical Device Required)

```bash
# CRITICAL: Must test on physical iPhone device per CLAUDE.md
# Build and deploy to device  
cd "/Users/colinmignot/Cursor/Ios Voice Control/PRPs-agentic-eng"
time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphoneos/VoiceControlApp.app -i 2b51e8a8e9ffe69c13296dd6673c5e0d47027e14

# Manual Testing Checklist:
# 1. App launches and shows authentication screen
# 2. Sign in with Google account works
# 3. VoiceControlMainView appears with microphone button
# 4. Tap microphone button - permission dialog appears
# 5. Grant microphone permission
# 6. Tap microphone button again - recording starts (red button, "Listening..." text)
# 7. Speak into microphone - text appears in real-time in text box
# 8. Tap microphone button again - recording stops
# 9. Final transcribed text remains in text box

# Expected: Real-time speech-to-text works end-to-end
# If error: Use log capture from CLAUDE.md to debug issues
```

### Level 4: Device Log Validation (Use CLAUDE.md Patterns)

```bash
# Capture device logs for debugging per CLAUDE.md workflow
# After testing, grab logs to verify functionality

# BASIC LOG CAPTURE (AssemblyAI specific)
tail -200 /var/log/system.log | grep -E "(VoiceControlApp|AssemblyAI|WebSocket)" | head -30

# AUDIO ISSUES LOG CAPTURE  
tail -300 /var/log/system.log | grep -E "(Audio|AVAudioEngine|microphone)" | head -20

# WEBSOCKET ERRORS LOG CAPTURE
tail -100 /var/log/system.log | grep -E "(WebSocket|Starscream|connection.*error)" | head -15

# Expected: No critical errors, successful WebSocket connections, audio capture working
# If issues: Analyze logs, fix problems, rebuild and retest
```

## Final Validation Checklist

- [ ] Clean build with no Swift compiler errors: `ios-deploy build succeeds`
- [ ] Unit tests pass: `xcodebuild test` succeeds  
- [ ] Manual test on physical iPhone device successful
- [ ] Microphone permission granted and working
- [ ] WebSocket connects to AssemblyAI successfully
- [ ] Real-time audio capture and streaming functional
- [ ] Transcribed text appears immediately in UI
- [ ] Recording start/stop states work correctly
- [ ] Error cases handled gracefully (network issues, permission denied)
- [ ] Device logs show no critical errors
- [ ] Integration preserves existing authentication flow

---

## Anti-Patterns to Avoid

- ❌ Don't use iOS Simulator - always test on physical device per CLAUDE.md
- ❌ Don't hardcode AssemblyAI API key in iOS app - use temporary tokens
- ❌ Don't use AVAudioRecorder for streaming - use AVAudioEngine for real-time
- ❌ Don't ignore microphone permissions - handle denial gracefully
- ❌ Don't send base64 audio to AssemblyAI - use binary WebSocket data
- ❌ Don't start audio capture before WebSocket connects - synchronize properly
- ❌ Don't forget to stop audio engine when stopping recording - prevent battery drain
- ❌ Don't skip error handling for network issues - WebSocket can disconnect
- ❌ Don't modify existing authentication patterns - follow established app architecture

---

## Confidence Score: 9/10

This PRP provides comprehensive context for one-pass implementation success through:
- ✅ Complete AssemblyAI WebSocket API documentation and requirements
- ✅ Detailed iOS audio capture implementation patterns  
- ✅ Existing codebase analysis and integration points
- ✅ Step-by-step task breakdown with specific file modifications
- ✅ Validation strategy using physical device testing (per CLAUDE.md)
- ✅ Critical gotchas and anti-patterns from research
- ✅ Authentication and security best practices

The only uncertainty (1 point deduction) is server-side temporary token generation, which may require additional backend work beyond the iOS app scope.