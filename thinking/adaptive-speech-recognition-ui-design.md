# Adaptive Speech Recognition UI Design
## Moon-Orbit Toggle System for iOS Voice Control App

### 🌙 Core Concept: Orbital UI Pattern

The app currently uses AssemblyAI as the primary speech recognition engine (main record button). We want to add the option to switch to iOS Speech Framework for quiet environments where speed matters more than noise handling.

Just like the moon orbits the Earth, a small toggle button orbits around the main record button to switch between the two speech recognition engines.

**Visual Metaphor:**
- **🌍 Earth (Main Button)**: Primary record button with AssemblyAI (always center)
- **🌙 Moon (Toggle)**: Smaller button that orbits to switch engines
- **🔄 Orbit Path**: Subtle arc indicating toggle positions
- **🎨 Color Transformation**: Main button changes color to signal active engine

---

## 🎯 User Experience Flow

### **Professional Mode (Default - AssemblyAI)**
```
🔊 AssemblyAI Recognition Active (Current System)
├── Main Button: Orange/Amber color (professional grade)
├── Moon Toggle: Position 0° (top-right, default)
├── Icon: Cloud with enhanced waveform
└── Benefits: Superior noise handling, professional accuracy, handles mixing environments
```

### **Fast Mode (iOS Speech Alternative)**
```
🔇 iOS Speech Recognition Active (New Addition)
├── Main Button: Blue/Default color 
├── Moon Toggle: Position 60° (right side)
├── Icon: iOS speech waveform
└── Benefits: Ultra-low latency, free usage, offline capable, quiet environments
```

---

## 📱 SwiftUI Implementation Concept

### **Main Interface Structure**
```swift
struct AdaptiveVoiceControlView: View {
    @StateObject private var speechManager = AdaptiveSpeechManager()
    @State private var recordButtonScale: CGFloat = 1.0
    @State private var moonAngle: Double = 0 // 0°, 60°, 120°
    
    var body: some View {
        ZStack {
            // Main Record Button (Earth)
            RecordButton(
                isRecording: speechManager.isRecording,
                mode: speechManager.currentMode,
                scale: recordButtonScale
            )
            .scaleEffect(recordButtonScale)
            
            // Orbital Toggle (Moon)
            MoonToggleButton(
                angle: moonAngle,
                currentMode: speechManager.currentMode,
                onToggle: { newMode in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        speechManager.switchMode(to: newMode)
                        updateMoonPosition(for: newMode)
                        updateButtonAppearance(for: newMode)
                    }
                }
            )
            
            // Orbit Path Indicator
            OrbitPathView(angle: moonAngle)
                .opacity(0.3)
        }
    }
}
```

### **Speech Recognition Modes**
```swift
enum SpeechRecognitionMode: CaseIterable {
    case professional  // AssemblyAI (default)
    case fast          // iOS Speech Framework
    
    var color: Color {
        switch self {
        case .professional: return .orange  // Professional grade
        case .fast: return .blue           // Fast response
        }
    }
    
    var icon: String {
        switch self {
        case .professional: return "cloud.fill"    // AssemblyAI cloud processing
        case .fast: return "waveform"              // iOS local processing
        }
    }
    
    var description: String {
        switch self {
        case .professional: return "Pro Accuracy"  // Handles noise, music, mixing
        case .fast: return "Fast & Free"           // Low latency, offline
        }
    }
}
```

---

## 🎨 Visual Design Specifications

### **Main Record Button (Earth)**
```
Dimensions: 80pt diameter
Colors by Mode:
  - Professional: Orange (#FF9500) → Amber gradient (default, AssemblyAI)
  - Fast: Blue (#007AFF) → Light Blue gradient (iOS Speech)

States:
  - Idle: Solid color with subtle pulse
  - Recording: Pulsing animation with waveform
  - Processing: Spinning gradient ring
```

### **Moon Toggle Button**
```
Dimensions: 24pt diameter (30% of main button)
Orbit Radius: 60pt from main button center
Positions:
  - 0° (Professional): Top-right (default, AssemblyAI)
  - 60° (Fast): Right side (iOS Speech)

Animation: 
  - Spring transition between positions (0.6s duration)
  - Scale bounce on tap (1.0 → 1.2 → 1.0)
  - Color fade transition matching main button
```

### **Orbit Path Indicator**
```
Style: Dashed arc (120° total span)
Opacity: 0.3 (subtle guide)
Color: Matches current mode
Width: 1pt line
Animation: Fade in/out on interaction
```

---

## 🔧 Interaction Behaviors

### **Toggle Activation**
1. **Tap Moon**: Toggles between modes (Professional ↔ Fast)
2. **Long Press Moon**: Shows mode selection popup with descriptions
3. **Drag Moon**: Allows direct positioning to desired angle
4. **Double Tap Main**: Quick toggle between Professional/Fast modes

### **Visual Feedback**
```swift
// Mode Change Animation Sequence
func switchToFastMode() {
    withAnimation(.easeInOut(duration: 0.3)) {
        // 1. Moon moves to 60° position
        moonAngle = 60
        
        // 2. Main button color shifts from orange to blue
        mainButtonColor = .blue
        
        // 3. Haptic feedback (medium impact)
        HapticManager.mediumImpact()
        
        // 4. Brief scale bounce
        recordButtonScale = 1.1
    }
    
    // 5. Scale back to normal
    withAnimation(.spring(response: 0.4)) {
        recordButtonScale = 1.0
    }
}
```

### **Status Indicators**
- **Badge on Moon**: Shows current engine (waveform/cloud icons)
- **Main Button Border**: Subtle ring color indicates active engine
- **Status Text**: Below buttons showing "iOS Speech" or "AssemblyAI Pro"

---

## 📊 Performance Indicators

### **Real-Time Feedback**
```swift
struct PerformanceIndicator: View {
    let currentMode: SpeechRecognitionMode
    let latency: TimeInterval
    let accuracy: Float
    let noiseLevel: Float
    
    var body: some View {
        HStack(spacing: 8) {
            // Latency indicator
            LatencyMeter(latency: latency, mode: currentMode)
            
            // Accuracy confidence
            AccuracyBar(accuracy: accuracy)
            
            // Noise level (when in noisy mode)
            if currentMode == .noisy {
                NoiseLevelIndicator(level: noiseLevel)
            }
        }
        .padding(.top, 8)
    }
}
```

### **Mode Comparison Tooltip**
```
When user long-presses moon toggle:

┌──────────────────────────────────┐
│ 🔊 Professional (AssemblyAI)     │
│ 🎯 Superior accuracy            │
│ 🔊 Handles noise & music        │
│ 🎛️ Mixing environment ready     │
│ ☁️ Requires internet            │
├──────────────────────────────────┤
│ ⚡ Fast Mode (iOS Speech)        │
│ ⚡ <100ms latency              │
│ 💰 Free usage                  │
│ 📱 Works offline               │
│ 🔇 Best for quiet environments  │
└──────────────────────────────────┘
```

---

## 🎛️ Professional Audio Context

### **Smart Recommendations**
The app analyzes the current environment and suggests the optimal mode:

```swift
struct EnvironmentDetector {
    func recommendMode() -> SpeechRecognitionMode {
        let noiseLevel = AudioAnalyzer.shared.getCurrentNoiseLevel()
        let musicDetected = AudioAnalyzer.shared.detectsBackgroundMusic()
        let multipleVoices = AudioAnalyzer.shared.detectsMultipleSpeakers()
        
        if noiseLevel > -35.0 || musicDetected || multipleVoices {
            return .professional  // Stay with AssemblyAI for mixing
        } else {
            return .fast  // Switch to iOS Speech for quiet moments
        }
    }
}
```

### **Contextual Hints**
- **First Launch**: "AssemblyAI is active (professional grade). Tap moon for faster iOS Speech in quiet moments."
- **Quiet Detected**: Gentle vibration + blue glow on moon button suggesting fast mode
- **Mode Switch Success**: "Now using iOS Speech for ultra-low latency" / "Back to AssemblyAI professional mode"

---

## 🚀 Implementation Phases

### **Phase 1: Basic Orbital Toggle (1 week)**
- [ ] Implement iOS Speech Framework integration alongside existing AssemblyAI
- [ ] Create moon button orbiting main button at 60-degree positions
- [ ] Add spring animations for position changes between Professional/Fast modes
- [ ] Create color transformation system (orange ↔ blue)
- [ ] Basic toggle functionality between AssemblyAI (default) and iOS Speech

### **Phase 2: Enhanced UX (1 week)**
- [ ] Add performance indicators (latency comparison, accuracy metrics)
- [ ] Implement haptic feedback for mode switching
- [ ] Create mode description tooltips showing benefits of each engine
- [ ] Add visual feedback during recording (different waveforms per engine)

### **Phase 3: Smart Features (1 week)**
- [ ] Environment detection for smart mode recommendations
- [ ] Usage analytics to track engine performance
- [ ] A/B testing framework for engine comparison
- [ ] Advanced audio preprocessing for iOS Speech in noisy conditions

---

## 💡 Key Benefits

### **User Experience**
- **🎯 Intuitive**: Moon/Earth metaphor is immediately understandable
- **⚡ Fast**: One tap to switch between engines
- **🎨 Beautiful**: Smooth animations and color transformations
- **📱 Native**: Feels like a built-in iOS control
- **🔄 Familiar**: AssemblyAI remains default, iOS Speech as speed boost option

### **Technical Advantages**
- **🎛️ Professional**: AssemblyAI handles mixing environments (current strength)
- **⚡ Speed Option**: iOS Speech for ultra-low latency when noise isn't a factor
- **📊 Informed**: Users understand trade-offs (professional accuracy vs speed)
- **💰 Cost-Effective**: Option to use free iOS Speech when appropriate
- **🔄 Adaptive**: Can switch engines based on current environment

---

## 🔮 Future Enhancements

### **Smart Environment Detection**
- Machine learning model that learns user preferences and environments
- Automatic recommendations based on detected audio conditions
- Integration with external audio hardware (detect when monitors/mixing is active)

### **Customization Options**
- User-defined moon orbit positions and angles
- Custom color schemes for different engines
- Gesture shortcuts (swipe patterns to change modes quickly)

### **Professional Features**
- Engine presets for different venue types (Studio, Live, Broadcast)
- Integration with mixing console state (suggest AssemblyAI when mixing actively)
- Team sharing of optimal engine settings across audio engineers
- Performance analytics showing which engine works best in different scenarios

---

## 🎯 Implementation Focus for PRP Creation

### **Core Technical Requirements**
- **Existing Codebase**: Build on current AssemblyAI implementation in VoiceControlMainView.swift
- **iOS Speech Integration**: Add SFSpeechRecognizer alongside existing AssemblyAIStreamer
- **UI Components**: Create orbital toggle button with smooth animations
- **State Management**: Manage engine switching without disrupting current recording sessions
- **Performance Tracking**: Compare latency and accuracy between engines

### **Key Files to Reference**
- `VoiceControlMainView.swift` - Main recording interface where toggle will be added
- `AssemblyAIStreamer.swift` - Current speech recognition implementation
- `SpeechRecognition/` folder - Where iOS Speech components will be added
- `Authentication/` - For tracking usage and subscription limits per engine

### **Success Criteria**
- AssemblyAI remains default and primary engine (professional grade)
- iOS Speech available as fast alternative with clear visual distinction
- Smooth engine switching with proper state management
- Orbital UI animations feel native and intuitive
- Users understand when to use each engine based on environment

**This orbital UI pattern transforms the choice between professional accuracy (AssemblyAI) and ultra-low latency (iOS Speech) into an elegant, intuitive interface that maintains the app's professional focus while offering speed optimization for appropriate scenarios.**