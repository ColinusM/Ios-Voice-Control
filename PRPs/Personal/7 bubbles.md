# PRPs - Real-Time Voice Command Bubbles Integration

## Product Requirement Prompt (PRP)

**Feature Name**: Real-Time Voice Command Bubbles
**Target Platform**: iOS SwiftUI Voice Control App
**Integration Source**: Python Voice Command Tester Engine

## 🎯 Feature Overview

Integrate the professional audio voice command processing engine from `/voice-command-tester/` into the iOS Voice Control app to display real-time command bubbles in a top-down 5:5 layout as voice commands are recognized and processed.

## 📱 Visual Layout Specification

```
┌─────────────────────────────────────┐
│             MAIN CHAT               │
│  ┌─────────────────────────────────┐ │
│  │   [Existing Speech Text Box]    │ │
│  └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│              Action 1               │
│  ┌─────────────────────────────────┐ │
│  │ [Command Bubble - Rounded Rect] │ │
│  └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│              Action 2               │
│  ┌─────────────────────────────────┐ │
│  │ [Command Bubble - Rounded Rect] │ │
│  └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│              Action 3               │
│  ┌─────────────────────────────────┐ │
│  │ [Command Bubble - Rounded Rect] │ │
│  └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│              Action 4               │
│  ┌─────────────────────────────────┐ │
│  │ [Command Bubble - Rounded Rect] │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## 🔧 Technical Integration Requirements

### 1. Voice Command Engine Integration

**Source**: `/voice-command-tester/engine.py` - VoiceCommandEngine class
**Components to Integrate**:
- Professional audio terminology parsing
- Yamaha RCP command generation
- Channel/mix routing logic
- DCA/scene recall processing
- Effects and dynamics processing

### 2. Real-Time Processing Pipeline

**Current Flow**:
```
Speech Recognition → Transcription Text → Display
```

**New Flow**:
```
Speech Recognition → Transcription Text → Display
                  ↓
          Voice Command Engine → RCP Commands → Command Bubbles
```

### 3. Background Processing Requirements

- **Continuous Processing**: Engine runs in background during speech recognition
- **Real-Time Response**: Command bubbles appear instantly when commands are detected
- **Non-Blocking**: Voice command processing doesn't interrupt speech transcription
- **Thread Safety**: Background processing on separate queue from UI updates

## 🎨 UI Component Specifications

### Command Bubble Component
```swift
struct VoiceCommandBubble: View {
    let rcpCommand: RCPCommand
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Command description
            Text(rcpCommand.description)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // RCP command (technical)
            Text(rcpCommand.command)
                .font(.caption)
                .fontFamily(.monospaced)
                .foregroundColor(.secondary)
            
            // Confidence indicator
            HStack {
                Text("Confidence:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ProgressView(value: confidence)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(confidenceColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(confidenceColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .orange }
        else { return .red }
    }
}
```

### Command Bubbles Container
```swift
struct VoiceCommandBubblesView: View {
    @ObservedObject var commandProcessor: VoiceCommandProcessor
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(commandProcessor.recentCommands, id: \.id) { command in
                    VoiceCommandBubble(
                        rcpCommand: command.rcpCommand,
                        confidence: command.confidence
                    )
                    .transition(.asymmetric(
                        insertion: .slide.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: commandProcessor.recentCommands)
    }
}
```

## 🏗️ Architecture Integration Points

### 1. SpeechRecognitionManager Extension
**File**: `VoiceControlApp/SpeechRecognition/SpeechRecognitionManager.swift`

Add voice command processing integration:
```swift
class SpeechRecognitionManager: ObservableObject {
    // Existing properties...
    @Published var voiceCommandProcessor = VoiceCommandProcessor()
    
    // In transcription handling:
    private func handleTranscriptionResult(_ result: String) {
        // Existing transcription logic...
        
        // NEW: Process for voice commands
        voiceCommandProcessor.processTranscription(result)
    }
}
```

### 2. New VoiceCommandProcessor Service
**New File**: `VoiceControlApp/VoiceCommand/VoiceCommandProcessor.swift`

Swift adaptation of Python engine:
```swift
class VoiceCommandProcessor: ObservableObject {
    @Published var recentCommands: [ProcessedVoiceCommand] = []
    
    private let maxCommands = 10
    private let confidenceThreshold = 0.5
    
    func processTranscription(_ text: String) {
        // Background processing
        Task.detached { [weak self] in
            let commands = await self?.extractVoiceCommands(from: text) ?? []
            
            await MainActor.run {
                self?.updateCommands(commands)
            }
        }
    }
    
    private func extractVoiceCommands(from text: String) async -> [ProcessedVoiceCommand] {
        // Swift implementation of Python engine logic
        // Pattern matching for audio commands
        // Professional terminology recognition
        // RCP command generation
    }
}
```

### 3. VoiceControlMainView Integration
**File**: `VoiceControlApp/VoiceControlMainView.swift`

Modify main view to include command bubbles:
```swift
struct VoiceControlMainView: View {
    // Existing properties...
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Existing header...
                
                // MODIFIED: Split main content area
                HStack(spacing: 0) {
                    // Left side: Existing speech text (50%)
                    VStack {
                        // Existing speech recognition UI
                        // Existing controls
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right side: Command bubbles (50%)
                    VStack {
                        Text("RCP Commands")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        VoiceCommandBubblesView(
                            commandProcessor: speechManager.voiceCommandProcessor
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                
                // Existing controls at bottom...
            }
        }
    }
}
```

## 🔄 Data Flow Architecture

### 1. Input Processing
```
User Speech → AssemblyAI → Transcription Text
                        ↓
            VoiceCommandProcessor.processTranscription()
                        ↓
              Background Command Analysis
                        ↓
                 RCP Command Generation
                        ↓
            UI Update (Command Bubbles)
```

### 2. Command Processing Pipeline
```swift
struct ProcessedVoiceCommand: Identifiable {
    let id = UUID()
    let originalText: String
    let rcpCommand: RCPCommand
    let confidence: Double
    let timestamp: Date
    let category: CommandCategory
}

struct RCPCommand {
    let command: String        // "set MIXER:Current/Channel/Fader/Level 0 0 -600"
    let description: String    // "Set channel 1 to -6.0 dB"
    let confidence: Double     // 0.85
}

enum CommandCategory {
    case channelFader
    case channelMute
    case routing
    case effects
    case scene
    case dca
    case unknown
}
```

## 🎪 Animation Specifications

### Command Bubble Entrance
- **Animation**: Slide in from right with spring physics
- **Duration**: 0.5 seconds
- **Easing**: Spring (response: 0.5, dampingFraction: 0.8)
- **Stagger**: 0.1 second delay between multiple commands

### Command Bubble Exit
- **Animation**: Fade out with scale down
- **Duration**: 0.3 seconds
- **Trigger**: After 30 seconds OR when list exceeds 10 items

### Real-Time Updates
- **Continuous Processing**: Every 500ms during active speech recognition
- **Debouncing**: 1 second after speech stops before final processing
- **Smooth Transitions**: All list updates use SwiftUI animations

## 🔧 Implementation Phases

### Phase 1: Core Integration (Foundation)
1. Create `VoiceCommandProcessor` service class
2. Implement basic pattern matching from Python engine
3. Add command bubble UI components
4. Integrate with existing `SpeechRecognitionManager`

### Phase 2: Professional Audio Engine (Core Logic)
1. Port professional terminology database
2. Implement channel/mix processing logic
3. Add DCA and scene recall processing
4. Implement effects and dynamics processing

### Phase 3: Real-Time UI (User Experience)
1. Implement real-time background processing
2. Add smooth animations and transitions
3. Optimize performance for continuous processing
4. Add command history and filtering

### Phase 4: Polish & Enhancement (Nice-to-Have)
1. Add command confidence visualization
2. Implement command editing/correction
3. Add export functionality for RCP commands
4. Add professional audio workflow presets

## 🛡️ Performance Considerations

### Background Processing
- Use `Task.detached` for command processing
- Implement processing queue with rate limiting
- Cache compiled regex patterns for performance
- Limit command history to prevent memory bloat

### UI Optimization
- Use `LazyVStack` for command list rendering
- Implement view recycling for large command lists
- Debounce UI updates during rapid speech input
- Use `@State` for local UI updates, `@Published` for data

### Memory Management
- Auto-cleanup old commands (30 second retention)
- Implement command deduplication logic
- Use weak references in async operations
- Profile memory usage during extended sessions

## 🧪 Testing Strategy

### Unit Tests
- Voice command pattern matching accuracy
- RCP command generation correctness  
- Professional terminology recognition
- Edge cases and malformed input handling

### Integration Tests
- Real-time processing performance
- UI update responsiveness
- Speech recognition integration
- Background processing stability

### User Experience Tests
- Command bubble appearance timing
- Animation smoothness
- Command accuracy during continuous speech
- UI responsiveness under load

## 📋 Success Metrics

### Functional Requirements
- ✅ Commands appear within 500ms of recognition
- ✅ 90%+ accuracy for professional audio terminology
- ✅ Smooth animations without UI blocking
- ✅ Background processing without speech interruption

### Performance Requirements
- ✅ <100ms processing time per command
- ✅ <50MB memory usage for command history
- ✅ 60fps UI performance during animations
- ✅ No speech recognition latency increase

### User Experience Requirements
- ✅ Intuitive command bubble layout
- ✅ Clear confidence indicators
- ✅ Professional audio workflow support
- ✅ Seamless integration with existing UI

## 🔗 Related Files & Dependencies

### Existing iOS App Files
- `VoiceControlApp/VoiceControlMainView.swift` - Main UI integration point
- `VoiceControlApp/SpeechRecognition/SpeechRecognitionManager.swift` - Speech processing
- `VoiceControlApp/SpeechRecognition/AssemblyAIStreamer.swift` - Real-time transcription

### Python Engine Source (Reference)
- `voice-command-tester/engine.py` - Main command processing engine
- `voice-command-tester/terms.py` - Professional audio terminology
- `voice-command-tester/channels.py` - Channel/mix processing logic
- `voice-command-tester/routing.py` - Audio routing commands
- `voice-command-tester/effects.py` - Effects and dynamics processing

### New iOS Files to Create
- `VoiceControlApp/VoiceCommand/VoiceCommandProcessor.swift`
- `VoiceControlApp/VoiceCommand/Models/RCPCommand.swift`
- `VoiceControlApp/VoiceCommand/Models/ProcessedVoiceCommand.swift`
- `VoiceControlApp/VoiceCommand/Components/VoiceCommandBubble.swift`
- `VoiceControlApp/VoiceCommand/Components/VoiceCommandBubblesView.swift`
- `VoiceControlApp/VoiceCommand/Services/ProfessionalAudioTerms.swift`

---

**Ready for `/create-base-prp` processing** ✅

This PRP provides comprehensive technical specifications for integrating the voice command engine with real-time command bubbles in the iOS Voice Control app, maintaining professional audio workflow support while delivering an intuitive user experience.