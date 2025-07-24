import SwiftUI

// MARK: - Orbital Toggle Button Component

/// Moon button that orbits around the main record button for speech engine switching
/// Animates between two positions: 0° (Professional/AssemblyAI) and 60° (Fast/iOS Speech)
struct OrbitalToggleButton: View {
    
    // MARK: - Properties
    
    /// Current orbital angle in degrees
    let angle: Double
    
    /// Current speech recognition mode
    let currentMode: SpeechRecognitionMode
    
    /// Whether the engine is currently switching
    let isSwitchingEngines: Bool
    
    /// Callback for engine toggle action
    let onToggle: (SpeechRecognitionMode) -> Void
    
    // MARK: - State
    
    @State private var dragOffset: CGSize = .zero
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var rotationAngle: Double = 0
    
    // MARK: - Constants
    
    private let orbitRadius: CGFloat = 60
    private let moonSize: CGFloat = 24
    private let orbitIndicatorOpacity: Double = 0.3
    private let shadowRadius: CGFloat = 3
    private let pressedShadowRadius: CGFloat = 6
    private let pressedScale: CGFloat = 1.2
    private let normalScale: CGFloat = 1.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Orbit path indicator (subtle visual guidance)
            orbitPathIndicator
            
            // Moon button positioned via polar coordinates
            moonButton
                .offset(polarToCartesian(angle: angle + rotationAngle, radius: orbitRadius))
                .offset(dragOffset)
                .scaleEffect(buttonScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: angle)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rotationAngle)
                .gesture(dragGesture)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var orbitPathIndicator: some View {
        Circle()
            .stroke(currentMode.color.opacity(orbitIndicatorOpacity), lineWidth: 1)
            .frame(width: orbitRadius * 2, height: orbitRadius * 2)
            .opacity(isDragging ? 0.6 : 0.3)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
    
    @ViewBuilder
    private var moonButton: some View {
        Button(action: performToggle) {
            ZStack {
                // Button background with engine color
                Circle()
                    .fill(buttonBackground)
                    .frame(width: moonSize, height: moonSize)
                    .shadow(color: currentMode.color.opacity(0.4), radius: shadowRadius)
                
                // Engine icon
                Image(systemName: currentMode.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationAngle * 0.5)) // Subtle rotation during drag
                
                // Loading indicator during engine switch
                if isSwitchingEngines {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.6)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.3))
                                .frame(width: moonSize, height: moonSize)
                        )
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevent default button animations
        .disabled(isSwitchingEngines)
        .onLongPressGesture(minimumDuration: 0) { } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonScale: CGFloat {
        if isSwitchingEngines {
            return 0.9
        } else if isPressed || isDragging {
            return pressedScale
        } else {
            return normalScale
        }
    }
    
    private var buttonBackground: some View {
        let baseColor = currentMode.color
        
        if isSwitchingEngines {
            return baseColor.opacity(0.7)
        } else if isPressed || isDragging {
            return baseColor.lighter(by: 0.1)
        } else {
            return baseColor
        }
    }
    
    private var shadowRadius: CGFloat {
        if isPressed || isDragging {
            return pressedShadowRadius
        } else {
            return self.shadowRadius
        }
    }
    
    private var accessibilityLabel: String {
        if isSwitchingEngines {
            return "Switching to \(nextMode.displayName)"
        } else {
            return "Switch to \(nextMode.displayName) mode"
        }
    }
    
    private var accessibilityHint: String {
        if isSwitchingEngines {
            return "Please wait while switching speech recognition engines"
        } else {
            return "Double tap to switch from \(currentMode.displayName) to \(nextMode.displayName)"
        }
    }
    
    private var nextMode: SpeechRecognitionMode {
        return currentMode == .professional ? .fast : .professional
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                handleDragChanged(value)
            }
            .onEnded { value in
                handleDragEnded(value)
            }
    }
    
    // MARK: - Private Methods
    
    private func polarToCartesian(angle: Double, radius: CGFloat) -> CGSize {
        let radians = angle * .pi / 180
        return CGSize(
            width: radius * cos(radians),
            height: radius * sin(radians)
        )
    }
    
    private func performToggle() {
        guard !isSwitchingEngines else { return }
        
        // Haptic feedback
        generateHapticFeedback(.medium)
        
        // Visual feedback
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            rotationAngle += 45 // Quick spin animation
        }
        
        // Reset rotation after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                rotationAngle = 0
            }
        }
        
        // Trigger engine switch
        let newMode = nextMode
        onToggle(newMode)
        
        print("🌙 Orbital toggle: switching to \(newMode.displayName)")
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // Enable dragging state
        if !isDragging {
            withAnimation(.easeInOut(duration: 0.1)) {
                isDragging = true
            }
        }
        
        // Calculate drag offset with orbital constraints
        let translation = value.translation
        let constrainedOffset = constrainToOrbit(translation)
        
        dragOffset = constrainedOffset
        
        // Add subtle rotation based on drag direction
        let dragAngle = atan2(translation.y, translation.x) * 180 / .pi
        rotationAngle = dragAngle * 0.1 // Subtle rotation effect
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let velocity = value.velocity
        let translation = value.translation
        
        // Determine if drag was significant enough to trigger toggle
        let dragMagnitude = sqrt(translation.x * translation.x + translation.y * translation.y)
        let dragThreshold: CGFloat = 30
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isDragging = false
            dragOffset = .zero
            
            // Check if drag should trigger a toggle
            if dragMagnitude > dragThreshold || abs(velocity.magnitude) > 300 {
                // Significant drag - trigger toggle
                performToggle()
            } else {
                // Return to original position
                rotationAngle = 0
            }
        }
        
        // Light haptic feedback on drag end
        generateHapticFeedback(.light)
    }
    
    private func constrainToOrbit(_ translation: CGSize) -> CGSize {
        // Constrain drag to stay within orbital bounds
        let maxOffset: CGFloat = orbitRadius * 0.3
        
        let constrainedX = max(-maxOffset, min(maxOffset, translation.x))
        let constrainedY = max(-maxOffset, min(maxOffset, translation.y))
        
        return CGSize(width: constrainedX, height: constrainedY)
    }
    
    private func generateHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Velocity Extension

private extension CGSize {
    var magnitude: Double {
        return sqrt(width * width + height * height)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Professional mode (orange, 0°)
        ZStack {
            Circle()
                .fill(.gray.opacity(0.1))
                .frame(width: 80, height: 80)
            
            OrbitalToggleButton(
                angle: 0,
                currentMode: .professional,
                isSwitchingEngines: false,
                onToggle: { mode in
                    print("Toggled to: \(mode.displayName)")
                }
            )
        }
        .frame(height: 160)
        
        // Fast mode (blue, 60°)
        ZStack {
            Circle()
                .fill(.gray.opacity(0.1))
                .frame(width: 80, height: 80)
            
            OrbitalToggleButton(
                angle: 60,
                currentMode: .fast,
                isSwitchingEngines: false,
                onToggle: { mode in
                    print("Toggled to: \(mode.displayName)")
                }
            )
        }
        .frame(height: 160)
        
        // Switching state
        ZStack {
            Circle()
                .fill(.gray.opacity(0.1))
                .frame(width: 80, height: 80)
            
            OrbitalToggleButton(
                angle: 30,
                currentMode: .professional,
                isSwitchingEngines: true,
                onToggle: { mode in
                    print("Toggled to: \(mode.displayName)")
                }
            )
        }
        .frame(height: 160)
    }
    .padding()
}