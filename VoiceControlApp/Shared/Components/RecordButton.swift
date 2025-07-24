import SwiftUI

// MARK: - Enhanced Record Button Component

/// Main record button (Earth) that changes appearance based on active speech engine
/// Serves as the center of the orbital toggle system with engine-specific theming
struct RecordButton: View {
    
    // MARK: - Properties
    
    /// Whether recording is currently active
    let isRecording: Bool
    
    /// Current speech recognition mode
    let mode: SpeechRecognitionMode
    
    /// Whether engine switching is in progress
    let isSwitchingEngines: Bool
    
    /// Current connection state
    let connectionState: StreamingState
    
    /// Callback for tap action
    let onTap: () -> Void
    
    // MARK: - State
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 4
    @State private var isPressed = false
    
    // MARK: - Constants
    
    private let buttonSize: CGFloat = 80
    private let iconSize: CGFloat = 32
    private let recordingScale: CGFloat = 1.1
    private let pressedScale: CGFloat = 0.95
    private let normalScale: CGFloat = 1.0
    private let baseShadowRadius: CGFloat = 4
    private let recordingShadowRadius: CGFloat = 8
    private let pressedShadowRadius: CGFloat = 2
    
    // MARK: - Body
    
    var body: some View {
        Button(action: performTap) {
            ZStack {
                // Background circle with engine-specific color
                Circle()
                    .fill(buttonBackgroundGradient)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: shadowColor, radius: shadowRadius)
                
                // Recording pulse ring
                if isRecording && !isSwitchingEngines {
                    recordingPulseRing
                }
                
                // Engine status indicator ring
                engineStatusRing
                
                // Main content
                buttonContent
                
                // Engine switching overlay
                if isSwitchingEngines {
                    engineSwitchingOverlay
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(buttonScale)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.4), value: mode)
        .animation(.easeInOut(duration: 0.3), value: isSwitchingEngines)
        .onLongPressGesture(minimumDuration: 0) { } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                shadowRadius = pressing ? pressedShadowRadius : (isRecording ? recordingShadowRadius : baseShadowRadius)
            }
        }
        .onAppear {
            startRecordingAnimation()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isRecording ? "Recording" : "Not recording")
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var recordingPulseRing: some View {
        Circle()
            .stroke(mode.color.opacity(0.3), lineWidth: 2)
            .frame(width: buttonSize + 20, height: buttonSize + 20)
            .scaleEffect(pulseScale)
            .opacity(2.0 - pulseScale) // Fade out as it scales up
    }
    
    @ViewBuilder
    private var engineStatusRing: some View {
        Circle()
            .stroke(statusRingColor, lineWidth: statusRingWidth)
            .frame(width: buttonSize + 8, height: buttonSize + 8)
            .opacity(statusRingOpacity)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        Group {
            if isRecording {
                recordingContent
            } else {
                idleContent
            }
        }
    }
    
    @ViewBuilder
    private var recordingContent: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: iconSize, weight: .medium))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 2)
    }
    
    @ViewBuilder
    private var idleContent: some View {
        VStack(spacing: 2) {
            Image(systemName: currentMicIcon)
                .font(.system(size: iconSize * 0.8, weight: .medium))
                .foregroundColor(.white)
            
            // Engine mode indicator
            Text(mode.shortName)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 2)
    }
    
    @ViewBuilder
    private var engineSwitchingOverlay: some View {
        ZStack {
            // Semi-transparent overlay
            Circle()
                .fill(.black.opacity(0.4))
                .frame(width: buttonSize, height: buttonSize)
            
            // Switching indicator
            VStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                
                Text("Switching")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonScale: CGFloat {
        if isSwitchingEngines {
            return normalScale * 0.95
        } else if isPressed {
            return pressedScale
        } else if isRecording {
            return recordingScale
        } else {
            return normalScale
        }
    }
    
    private var buttonBackgroundGradient: LinearGradient {
        let baseColor = isRecording ? Color.red : mode.color
        
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor.lighter(by: 0.1),
                baseColor,
                baseColor.darker(by: 0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shadowColor: Color {
        if isRecording {
            return Color.red.opacity(0.4)
        } else {
            return mode.color.opacity(0.4)
        }
    }
    
    private var statusRingColor: Color {
        switch connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .yellow
        case .connected:
            return mode.color
        case .streaming:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusRingWidth: CGFloat {
        switch connectionState {
        case .streaming:
            return 3
        case .error:
            return 3
        default:
            return 2
        }
    }
    
    private var statusRingOpacity: Double {
        switch connectionState {
        case .disconnected:
            return 0.3
        case .connecting:
            return 0.6
        case .connected, .streaming:
            return 0.8
        case .error:
            return 1.0
        }
    }
    
    private var currentMicIcon: String {
        switch connectionState {
        case .disconnected:
            return "mic.slash"
        case .connecting:
            return "mic.badge.plus"
        case .connected, .streaming:
            return mode.icon
        case .error:
            return "mic.slash.fill"
        }
    }
    
    private var accessibilityLabel: String {
        if isSwitchingEngines {
            return "Switching speech recognition engine"
        } else if isRecording {
            return "Stop recording with \(mode.displayName)"
        } else {
            return "Start recording with \(mode.displayName)"
        }
    }
    
    private var accessibilityHint: String {
        if isSwitchingEngines {
            return "Please wait while the speech engine is switching"
        } else if isRecording {
            return "Tap to stop recording and save your speech"
        } else {
            return "Tap to start recording speech with \(mode.displayName) engine"
        }
    }
    
    // MARK: - Private Methods
    
    private func performTap() {
        guard !isSwitchingEngines else {
            return
        }
        
        // Generate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Call the action
        onTap()
        
        print("🎤 Record button tapped - Mode: \(mode.displayName), Recording: \(isRecording)")
    }
    
    private func startRecordingAnimation() {
        guard isRecording && !isSwitchingEngines else {
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
        
        // Restart animation if recording state changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isRecording && !isSwitchingEngines {
                startRecordingAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

// MARK: - Color Extensions for Enhanced Effects

private extension Color {
    
    func lighter(by percentage: Double = 0.1) -> Color {
        return Color(UIColor(self).lighter(by: percentage))
    }
    
    func darker(by percentage: Double = 0.1) -> Color {
        return Color(UIColor(self).darker(by: percentage))
    }
}

private extension UIColor {
    
    func lighter(by percentage: Double = 0.1) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }
    
    func darker(by percentage: Double = 0.1) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }
    
    private func adjustBrightness(by percentage: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness = max(0, min(1, brightness + CGFloat(percentage)))
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Professional mode - not recording
        RecordButton(
            isRecording: false,
            mode: .professional,
            isSwitchingEngines: false,
            connectionState: .connected,
            onTap: { print("Professional tap") }
        )
        
        // Fast mode - recording
        RecordButton(
            isRecording: true,
            mode: .fast,
            isSwitchingEngines: false,
            connectionState: .streaming,
            onTap: { print("Fast tap") }
        )
        
        // Engine switching
        RecordButton(
            isRecording: false,
            mode: .professional,
            isSwitchingEngines: true,
            connectionState: .connecting,
            onTap: { print("Switching tap") }
        )
        
        // Error state
        RecordButton(
            isRecording: false,
            mode: .fast,
            isSwitchingEngines: false,
            connectionState: .error(.connectionFailed("Test error")),
            onTap: { print("Error tap") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}