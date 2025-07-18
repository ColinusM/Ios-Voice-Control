# Task 4: Graceful Shutdown - Speech Stop Recording

> Implement graceful shutdown that waits for final formatted transcript before cleanup

## Context

```yaml
context:
  docs:
    - url: AssemblyAI Real-time API v3
      focus: end_of_turn and turn_is_formatted flags

  patterns:
    - file: AssemblyAIStreamer.swift:236
      copy: formatted transcript filtering logic

  gotchas:
    - issue: "Final transcript in transit after stop button"
      fix: "Wait for end_of_turn: true + turn_is_formatted: true"
    - issue: "User expects immediate UI feedback"
      fix: "Stop audio immediately, show stopping state"
```

## Problem Analysis

**Current Issue**: AssemblyAI servers continue processing audio after stop button pressed, sending final formatted transcript that gets lost due to immediate WebSocket disconnection.

**Root Cause**: `stopStreaming()` method at line 72 immediately:
1. Stops audio recording
2. Sends session termination
3. Disconnects WebSocket 
4. Resets state

**Solution**: Implement graceful shutdown state machine.

## Implementation Tasks

### Phase 1: State Management Setup

```
READ VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - UNDERSTAND: Current state management (lines 8-26)
  - FIND: Published properties and private state
  - NOTE: connectionState enum needs graceful shutdown state

UPDATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND: enum StreamingState
  - ADD: case gracefulShutdown
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check enum case syntax and imports

UPDATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND: private var sessionBegun = false
  - ADD_AFTER: private var isGracefulShutdown = false
  - ADD_AFTER: private var gracefulShutdownTimer: Timer?
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check Timer import in Foundation
```

### Phase 2: Graceful Shutdown Logic

```
UPDATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND: func stopStreaming() {
  - REPLACE_WITH: func stopStreaming() {
      print("🛑 Starting graceful shutdown...")
      
      // Stop audio recording immediately (user feedback)
      audioManager.stopRecording()
      
      // Enter graceful shutdown state
      Task { @MainActor in
          isStreaming = false
          connectionState = .gracefulShutdown
          isGracefulShutdown = true
      }
      
      // Start graceful shutdown timer (5 second timeout)
      gracefulShutdownTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
          print("⏰ Graceful shutdown timeout - forcing cleanup")
          self?.forceCleanup()
      }
      
      // Don't disconnect WebSocket yet - wait for final transcript
      print("⏳ Waiting for final formatted transcript...")
  }
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check Timer import and weak self syntax
```

### Phase 3: Final Transcript Detection

```
UPDATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND: if turn.end_of_turn == true {
  - FIND: if let isFormatted = turn.turn_is_formatted, isFormatted == true {
  - ADD_AFTER: 
      // Check if we're in graceful shutdown and this is the final transcript
      if isGracefulShutdown {
          print("✅ Final formatted transcript received during graceful shutdown")
          completeGracefulShutdown()
          return
      }
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check completeGracefulShutdown method exists
```

### Phase 4: Cleanup Methods

```
UPDATE VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift:
  - FIND: print("✅ AssemblyAI streaming stopped")
  - ADD_BEFORE:
    private func completeGracefulShutdown() {
        print("🏁 Completing graceful shutdown with final transcript")
        
        // Cancel timer
        gracefulShutdownTimer?.invalidate()
        gracefulShutdownTimer = nil
        
        // Now do full cleanup
        forceCleanup()
    }
    
    private func forceCleanup() {
        print("🧹 Forcing cleanup")
        
        // Send session termination if still connected
        if isConnected {
            sendSessionTermination()
        }
        
        // Disconnect WebSocket
        webSocket?.disconnect()
        webSocket = nil
        
        // Reset state
        Task { @MainActor in
            connectionState = .disconnected
            sessionId = nil
            isConnected = false
            sessionBegun = false
            reconnectAttempts = 0
            isGracefulShutdown = false
            
            // Reset only current turn text, keep accumulated text
            currentTurnText = ""
            transcriptionText = accumulatedText
        }
        
        print("✅ AssemblyAI streaming stopped")
    }
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check method syntax and Task { @MainActor in } usage
```

### Phase 5: UI State Updates

```
READ VoiceControlApp/VoiceControlMainView.swift:
  - FIND: Button action for stop recording
  - NOTE: How UI responds to connectionState changes

UPDATE VoiceControlApp/VoiceControlMainView.swift:
  - FIND: switch assemblyAIStreamer.connectionState
  - ADD: case .gracefulShutdown:
      Text("Stopping...")
          .foregroundColor(.orange)
  - VALIDATE: Build compiles without errors
  - IF_FAIL: Check enum case matches AssemblyAIStreamer
```

## Validation Checkpoints

```
CHECKPOINT build:
  - RUN: cd /Users/colinmignot/Cursor/Ios\ Voice\ Control/PRPs-agentic-eng && time ios-deploy -b /Users/colinmignot/Library/Developer/Xcode/DerivedData/VoiceControlApp-*/Build/Products/Debug-iphonesimulator/VoiceControlApp.app -i 734CE727-9B7B-40B3-8D56-DB0A2C1C8CD8
  - REQUIRE: App launches successfully
  - DEBUG: Check Xcode build logs for errors

CHECKPOINT recording:
  - START: App on iPhone 16 iOS 18.5 simulator
  - ACTION: Press record button
  - SPEAK: "This is a test of graceful shutdown"
  - ACTION: Press stop button while speaking
  - EXPECT: "Stopping..." state shown
  - EXPECT: Final transcript appears after stop
  - VALIDATE: No duplicate text in final result

CHECKPOINT timeout:
  - START: App on iPhone 16 iOS 18.5 simulator  
  - ACTION: Press record button
  - SPEAK: "Test timeout behavior"
  - ACTION: Press stop button
  - WAIT: 6 seconds (past timeout)
  - EXPECT: App returns to normal state
  - VALIDATE: No hanging connections
```

## Debug Patterns

```
DEBUG missing_transcript:
  - CHECK: WebSocket still connected when stop pressed
  - CHECK: gracefulShutdownTimer created
  - ADD: print("🔍 Graceful shutdown state: \(isGracefulShutdown)")
  - TRACE: AssemblyAI messages after stop button
  - FIX: Verify end_of_turn detection logic

DEBUG ui_hanging:
  - CHECK: Timer invalidated properly
  - CHECK: forceCleanup() called
  - ADD: print("🔍 Connection state: \(connectionState)")
  - TRACE: MainActor state updates
  - FIX: Ensure all state updates on MainActor

DEBUG timeout_not_working:
  - CHECK: Timer.scheduledTimer syntax
  - CHECK: weak self capture
  - ADD: print("⏰ Timer fired")
  - TRACE: Timer invalidation
  - FIX: Verify timer runs on correct thread
```

## Testing Strategy

1. **Happy Path**: Record → Stop → Receive final transcript → Clean shutdown
2. **Timeout Path**: Record → Stop → No final transcript → Force cleanup after 5s
3. **Multiple Stops**: Record → Stop → Stop again → Should handle gracefully
4. **Network Issues**: Record → Stop → WebSocket error → Should cleanup
5. **Background/Foreground**: Record → Stop → App backgrounded → Should cleanup

## Rollback Plan

If graceful shutdown causes issues:
1. Revert to original `stopStreaming()` method
2. Keep immediate cleanup behavior
3. Accept loss of final transcript as acceptable tradeoff
4. Add user documentation about stopping early

## Success Criteria

- ✅ Audio stops immediately when stop button pressed
- ✅ UI shows "Stopping..." state during graceful shutdown
- ✅ Final formatted transcript captured and displayed
- ✅ Clean shutdown after final transcript or 5-second timeout
- ✅ No duplicate text in final result
- ✅ No hanging connections or memory leaks
- ✅ Multiple stop button presses handled gracefully

## Risk Assessment

**Low Risk**: 
- Audio stopping immediately (existing behavior)
- UI state management (well-tested pattern)

**Medium Risk**:
- Timer management (potential for leaks)
- WebSocket lifecycle (connection hanging)

**High Risk**:
- Race conditions between timer and transcript receipt
- Memory leaks from retained closures

**Mitigation**:
- Use weak self in timer closures
- Always invalidate timers in cleanup
- Force cleanup as fallback
- Comprehensive testing of edge cases