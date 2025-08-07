# Task Completion Guidelines - Android Voice Control App

## Standard Completion Workflow

### 1. Code Quality Validation
```bash
# Always run after code changes
cd AndroidVoiceControlApp

# Kotlin lint check
./gradlew lintDebug

# Static analysis (if configured)  
./gradlew detekt
```

### 2. Build Verification
```bash
# Build debug version
./gradlew assembleDebug

# Install on device/emulator
./gradlew installDebug

# Or combined
./gradlew assembleDebug && ./gradlew installDebug
```

### 3. Testing Validation
```bash
# Unit tests
./gradlew testDebugUnitTest

# Integration tests (requires device)
./gradlew connectedDebugAndroidTest

# Automated testing framework (RECOMMENDED)
cd ../android_testing_framework/
python3 android_mcp_tester.py --suite
```

### 4. Manual Testing Protocol
```bash
# Live monitoring during testing
cd ../android_testing_framework/
python3 android_mcp_tester.py --live

# Traditional log monitoring (backup method)
adb logcat -t 200 | grep "VoiceControlApp|SpeechRecognition|AssemblyAI" | head -50
```

### 5. Performance Verification
```bash
# Monitor memory usage
adb shell dumpsys meminfo com.voicecontrol.app

# Check for ANRs and crashes
adb logcat -t 100 | grep -E "(FATAL|AndroidRuntime|ANR)" | head -15

# Audio-specific monitoring
adb logcat -t 200 | grep -E "(AudioRecord|AudioManager)" | head -20
```

## Feature-Specific Validation

### Speech Recognition Features
1. **Permission Testing**: Verify RECORD_AUDIO permission request and handling
2. **Audio Quality**: Test with varying noise levels and speech volumes
3. **Network Resilience**: Test with poor connectivity and recovery
4. **State Management**: Verify UI state updates match service states
5. **Resource Cleanup**: Ensure AudioRecord and WebSocket cleanup on app exit

### UI Component Features  
1. **Animation Performance**: Verify 60fps animations during recording states
2. **Accessibility**: Test with TalkBack screen reader
3. **Responsive Design**: Test on different screen sizes and orientations
4. **Touch Responsiveness**: Verify button press feedback under load
5. **State Persistence**: Test screen rotation and app backgrounding

### Service Integration Features
1. **DI Verification**: Ensure all services inject correctly with Hilt
2. **StateFlow Integration**: Verify reactive UI updates from service state
3. **Error Propagation**: Test error states flow from services to UI
4. **Configuration Management**: Test runtime configuration changes
5. **Lifecycle Management**: Test service cleanup in various scenarios

## Quality Gates

### Code Coverage
- Unit tests must cover core business logic (ViewModel, Service classes)
- Integration tests must cover main user flows
- UI tests must cover critical user interactions

### Performance Benchmarks
- Audio latency < 200ms for visual feedback
- UI animations maintain 60fps during recording
- Memory usage remains stable during 5-minute recording sessions
- No memory leaks detected in service lifecycle

### Reliability Standards
- No crashes during normal operation
- Graceful error handling with user-friendly messages  
- Service recovery after network interruptions
- Proper resource cleanup on app termination

## Debugging Best Practices

### Structured Logging Review
```bash
# Check for proper log structure
adb logcat -t 500 | grep "VoiceControlApp" | grep -E "(🚀|✅|🛑|⚠️|❌)"

# Verify error handling logs
adb logcat -t 200 | grep -E "(❌|⚠️)" | head -20
```

### State Flow Validation
- Verify StateFlow emission patterns in logs
- Check for proper state transitions (Starting → Recording → Processing → Stopped)
- Ensure UI state updates match service state changes
- Validate error state propagation and recovery

### Service Integration Validation
- Confirm DI graph construction (no missing dependencies)
- Verify service singleton behavior
- Check proper cleanup in service destructors
- Validate coroutine scope management

## Pre-Commit Checklist

### Required Validations
- [ ] Code builds without warnings: `./gradlew assembleDebug`
- [ ] Unit tests pass: `./gradlew testDebugUnitTest`
- [ ] Lint checks pass: `./gradlew lintDebug`  
- [ ] Manual testing on physical device completed
- [ ] No memory leaks detected
- [ ] Performance requirements met
- [ ] Proper error handling verified
- [ ] Log patterns follow conventions

### Automated Testing Suite  
- [ ] `python3 android_mcp_tester.py --suite` passes all tests
- [ ] Mobile MCP automation confirms UI state changes
- [ ] Speech recognition test patterns validate correctly
- [ ] Network resilience tests pass

### Documentation Updates
- [ ] CLAUDE.md updated if commands changed
- [ ] Code comments added for complex logic
- [ ] TODO comments removed or addressed
- [ ] Memory files updated if architecture changed

## Post-Completion Verification

### Production Readiness
- App functions correctly on cold start
- All user flows work end-to-end  
- Error states display helpful messages
- Performance meets professional audio standards
- Battery usage is reasonable during operation

### Integration Testing
- Services integrate properly with existing authentication
- Network settings work with speech services
- Voice commands process correctly through full pipeline
- State persistence works across app lifecycle events

## Common Issue Resolution

### Build Failures
1. Clean and rebuild: `./gradlew clean && ./gradlew assembleDebug`
2. Check Java version: `java -version` (must be 17+)
3. Verify Android SDK installation
4. Check for dependency conflicts in build files

### Test Failures
1. Ensure device/emulator is connected: `adb devices`
2. Clear app data: `adb shell pm clear com.voicecontrol.app`  
3. Check permissions in device settings
4. Verify network connectivity for integration tests

### Performance Issues
1. Profile with Android Studio profiler
2. Check for main thread blocking operations
3. Review StateFlow emission patterns
4. Validate coroutine scope usage