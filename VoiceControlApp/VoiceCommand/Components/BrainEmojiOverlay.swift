import SwiftUI

/// Brain emoji overlay for learning prompts with 3-second auto-dismiss
/// Appears at top-right of successful command bubbles
struct BrainEmojiOverlay: View {
    
    // MARK: - Properties
    
    /// Whether the overlay is currently showing
    @Binding var isShowing: Bool
    
    /// Callback for accept button tap
    let onAccept: () -> Void
    
    /// Callback for reject button tap
    let onReject: () -> Void
    
    /// Learning prompt data to display
    let promptData: LearningPromptData?
    
    // MARK: - State
    
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    @State private var dismissTimer: Timer?
    @State private var progress: Double = 0
    
    // MARK: - Constants
    
    private let animationDuration: TimeInterval = 0.3
    private let autoDismissTimeout: TimeInterval = 3.0
    private let progressAnimationDuration: TimeInterval = 3.0
    
    // MARK: - Initialization
    
    init(
        isShowing: Binding<Bool>,
        onAccept: @escaping () -> Void,
        onReject: @escaping () -> Void,
        promptData: LearningPromptData? = nil
    ) {
        self._isShowing = isShowing
        self.onAccept = onAccept
        self.onReject = onReject
        self.promptData = promptData
    }
    
    // MARK: - Body
    
    var body: some View {
        overlayContent
            .opacity(opacity)
            .scaleEffect(scale)
            .animation(.easeOut(duration: animationDuration), value: opacity)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: scale)
            .onAppear {
                startEntranceAnimation()
                startAutoDismissTimer()
                startProgressAnimation()
            }
            .onDisappear {
                cancelTimers()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Learning prompt")
            .accessibilityHint("Confirm if these commands are similar")
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var overlayContent: some View {
        ZStack {
            // Background with progress indicator
            backgroundView
            
            // Main content
            contentView
        }
        .frame(maxWidth: 200)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        // Background with subtle progress indication
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(progressColor, lineWidth: 2)
                    .scaleEffect(1 + (progress * 0.02)) // Subtle scale animation
                    .opacity(0.6)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 8) {
            // Brain emoji with similarity hint
            brainEmojiSection
            
            // Command comparison (if available)
            if let promptData = promptData {
                commandComparisonSection(promptData)
            }
            
            // Action buttons
            actionButtonsSection
        }
        .padding(12)
    }
    
    @ViewBuilder
    private var brainEmojiSection: some View {
        HStack(spacing: 4) {
            Text("🧠")
                .font(.system(size: 20))
                .accessibility(hidden: true)
            
            if let promptData = promptData {
                Text("\(Int(promptData.similarity * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func commandComparisonSection(_ promptData: LearningPromptData) -> some View {
        VStack(spacing: 2) {
            // Original command (what failed)
            Text(promptData.original)
                .font(.caption2)
                .foregroundColor(.red)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Arrow
            Image(systemName: "arrow.down")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            // Corrected command (what succeeded)
            Text(promptData.corrected)
                .font(.caption2)
                .foregroundColor(.green)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Accept button
            Button(action: handleAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            .accessibilityLabel("Accept similarity")
            .accessibilityHint("Mark these commands as similar")
            .buttonStyle(LearningButtonStyle(color: .green))
            
            // Reject button  
            Button(action: handleReject) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
            .accessibilityLabel("Reject similarity")
            .accessibilityHint("Mark these commands as different")
            .buttonStyle(LearningButtonStyle(color: .red))
        }
    }
    
    // MARK: - Computed Properties
    
    private var progressColor: Color {
        let intensity = 1.0 - progress
        return Color.blue.opacity(0.3 + (intensity * 0.4))
    }
    
    // MARK: - Actions
    
    private func handleAccept() {
        // Generate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0
            scale = 0.9
        }
        
        // Delay callback to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onAccept()
            isShowing = false
        }
        
        cancelTimers()
        
        print("✅ User accepted learning prompt")
    }
    
    private func handleReject() {
        // Generate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0
            scale = 1.1
        }
        
        // Delay callback to allow animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onReject()
            isShowing = false
        }
        
        cancelTimers()
        
        print("❌ User rejected learning prompt")
    }
    
    private func handleAutoDismiss() {
        guard isShowing else { return }
        
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }
        
        // Delay to complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if isShowing {
                isShowing = false
                print("⏭️ Learning prompt auto-dismissed")
            }
        }
    }
    
    // MARK: - Animation Management
    
    private func startEntranceAnimation() {
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 1.0
            scale = 1.0
        }
    }
    
    private func startAutoDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissTimeout, repeats: false) { _ in
            handleAutoDismiss()
        }
    }
    
    private func startProgressAnimation() {
        withAnimation(.linear(duration: progressAnimationDuration)) {
            progress = 1.0
        }
    }
    
    private func cancelTimers() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

// MARK: - Custom Button Style

/// Custom button style for learning prompt buttons
struct LearningButtonStyle: ButtonStyle {
    let color: Color
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .background(
                Circle()
                    .fill(color.opacity(0.1))
                    .scaleEffect(configuration.isPressed ? 1.2 : 0)
                    .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Example bubble background
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .frame(width: 300, height: 100)
                .shadow(radius: 4)
                .overlay(
                    VStack {
                        Text("Set channel 1 to -6 dB")
                            .font(.subheadline)
                        Text("Command sent successfully")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                )
                .overlay(
                    // Brain emoji overlay positioned at top-right
                    BrainEmojiOverlay(
                        isShowing: .constant(true),
                        onAccept: { print("Accepted!") },
                        onReject: { print("Rejected!") },
                        promptData: LearningPromptData(
                            id: UUID(),
                            original: "set channel one to minus six",
                            corrected: "set channel 1 to -6 dB",
                            similarity: 0.85,
                            confidence: 0.9,
                            editDistance: 2,
                            matchingWords: ["set", "channel", "to", "six"],
                            wasConsoleConnected: true,
                            createdAt: Date()
                        )
                    ),
                    alignment: .topTrailing
                )
            
            // Simple version without data
            BrainEmojiOverlay(
                isShowing: .constant(true),
                onAccept: { print("Simple Accept!") },
                onReject: { print("Simple Reject!") }
            )
        }
        .padding()
    }
}

// MARK: - Accessibility Helpers

extension BrainEmojiOverlay {
    
    /// Voice-over description of the learning prompt
    private var accessibilityDescription: String {
        guard let promptData = promptData else {
            return "Learning prompt for similar commands"
        }
        
        return """
        Learning prompt: \(Int(promptData.similarity * 100)) percent similarity between 
        '\(promptData.original)' and '\(promptData.corrected)'. 
        Choose accept to confirm similarity or reject to mark as different.
        """
    }
}

// MARK: - Extensions for Integration

extension BrainEmojiOverlay {
    
    /// Create overlay for VoiceCommandBubble integration
    /// - Parameters:
    ///   - promptManager: The learning prompt manager
    ///   - promptData: Current prompt data
    /// - Returns: Configured overlay view
    static func forBubbleIntegration(
        promptManager: LearningPromptManager,
        promptData: LearningPromptData?
    ) -> some View {
        BrainEmojiOverlay(
            isShowing: .init(
                get: { promptManager.showingPrompt },
                set: { _ in }
            ),
            onAccept: { promptManager.handleAcceptResponse() },
            onReject: { promptManager.handleRejectResponse() },
            promptData: promptData
        )
    }
}