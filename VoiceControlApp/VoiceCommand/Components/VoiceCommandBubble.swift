import SwiftUI

/// Individual voice command bubble component with confidence visualization
/// Displays RCP commands with professional styling and confidence indicators
struct VoiceCommandBubble: View {
    
    // MARK: - Properties
    
    /// The processed voice command to display
    let command: ProcessedVoiceCommand
    
    /// Whether to show detailed metadata (for debugging)
    let showMetadata: Bool
    
    /// Callback for bubble tap
    let onTap: (() -> Void)?
    
    /// Callback for send button tap
    let onSend: (() -> Void)?
    
    // MARK: - State
    
    @State private var isPressed = false
    @State private var animationProgress: Double = 0.0
    
    // MARK: - Constants
    
    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 1
    private let shadowRadius: CGFloat = 4
    private let contentPadding: CGFloat = 12
    private let confidenceBarHeight: CGFloat = 4
    private let metadataFontSize: CGFloat = 8
    
    // MARK: - Initialization
    
    init(
        command: ProcessedVoiceCommand,
        showMetadata: Bool = false,
        onTap: (() -> Void)? = nil,
        onSend: (() -> Void)? = nil
    ) {
        self.command = command
        self.showMetadata = showMetadata
        self.onTap = onTap
        self.onSend = onSend
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Command header with category and timestamp
                commandHeader
                
                // Command description (main content)
                commandDescription
                
                // RCP command (technical details)
                rcpCommandText
                
                // Confidence indicator
                confidenceIndicator
                
                // Send button
                if onSend != nil {
                    sendButton
                }
                
                // Processing metadata (if enabled)
                if showMetadata {
                    processingMetadata
                }
            }
            .padding(contentPadding)
            .background(bubbleBackground)
            .overlay(bubbleBorder)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
            .scaleEffect(bubbleScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.5), value: animationProgress)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Voice command bubble")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var commandHeader: some View {
        HStack {
            // Category badge
            Text(command.category.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(categoryColor)
                .cornerRadius(4)
            
            Spacer()
            
            // Timestamp and age
            VStack(alignment: .trailing, spacing: 1) {
                Text(timeFormatter.string(from: command.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if command.ageInSeconds > 5 {
                    Text("\(Int(command.ageInSeconds))s ago")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
    }
    
    @ViewBuilder
    private var commandDescription: some View {
        Text(command.rcpCommand.description)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var rcpCommandText: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(command.rcpCommand.command)
                .font(.caption)
                .monospaced()
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .frame(maxHeight: 20)
    }
    
    @ViewBuilder
    private var confidenceIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Confidence:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(command.confidencePercentage)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceTextColor)
            }
            
            // Confidence progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: confidenceBarHeight / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: confidenceBarHeight)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: confidenceBarHeight / 2)
                        .fill(confidenceGradient)
                        .frame(
                            width: geometry.size.width * animatedConfidence,
                            height: confidenceBarHeight
                        )
                        .animation(.easeInOut(duration: 0.8), value: animatedConfidence)
                }
            }
            .frame(height: confidenceBarHeight)
        }
    }
    
    @ViewBuilder
    private var processingMetadata: some View {
        Divider()
            .opacity(0.5)
        
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Processor:")
                    .font(.system(size: metadataFontSize))
                    .foregroundColor(.secondary)
                
                Text(command.processingMetadata.processorUsed)
                    .font(.system(size: metadataFontSize))
                    .monospaced()
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", command.processingMetadata.processingTimeMs))ms")
                    .font(.system(size: metadataFontSize))
                    .monospaced()
                    .foregroundColor(.secondary)
            }
            
            if command.processingMetadata.usedContext {
                Text("• Used context from previous commands")
                    .font(.system(size: metadataFontSize))
                    .foregroundColor(.secondary)
            }
            
            if command.processingMetadata.isCompoundCommand {
                Text("• Part of compound command")
                    .font(.system(size: metadataFontSize))
                    .foregroundColor(.secondary)
            }
            
            ForEach(command.processingMetadata.processingNotes, id: \.self) { note in
                Text("• \(note)")
                    .font(.system(size: metadataFontSize))
                    .foregroundColor(.orange)
            }
        }
    }
    
    @ViewBuilder
    private var sendButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                onSend?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Send")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 4)
    }
    
    // MARK: - Computed Properties
    
    private var bubbleScale: CGFloat {
        isPressed ? 0.96 : 1.0
    }
    
    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundGradient)
    }
    
    private var bubbleBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(borderColor, lineWidth: borderWidth)
    }
    
    private var backgroundGradient: LinearGradient {
        let baseColor = confidenceColor.opacity(0.1)
        
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor.lighter(by: 0.02),
                baseColor,
                baseColor.darker(by: 0.02)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderColor: Color {
        confidenceColor.opacity(0.3)
    }
    
    private var shadowColor: Color {
        confidenceColor.opacity(0.2)
    }
    
    private var confidenceColor: Color {
        switch command.confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var confidenceTextColor: Color {
        confidenceColor.darker(by: 0.2)
    }
    
    private var confidenceGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                confidenceColor.lighter(by: 0.1),
                confidenceColor,
                confidenceColor.darker(by: 0.1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var categoryColor: Color {
        switch command.category {
        case .channelFader:
            return .blue
        case .channelMute, .channelSolo:
            return .red
        case .routing:
            return .purple
        case .effects:
            return .green
        case .scene:
            return .orange
        case .dca:
            return .yellow
        case .eq, .dynamics:
            return .cyan
        case .labeling:
            return .gray
        case .unknown:
            return .secondary
        }
    }
    
    private var animatedConfidence: Double {
        animationProgress * command.confidence
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private var accessibilityLabel: String {
        return "Voice command: \(command.rcpCommand.description)"
    }
    
    private var accessibilityValue: String {
        return "Confidence \(command.confidencePercentage), Category: \(command.category.displayName)"
    }
    
    // MARK: - Private Methods
    
    private func handleTap() {
        guard let onTap = onTap else { return }
        
        // Generate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        onTap()
        
        print("🎯 Voice command bubble tapped: \(command.rcpCommand.description)")
    }
    
    private func startEntranceAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            animationProgress = 1.0
        }
    }
}

// MARK: - Color Extensions

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
    VStack(spacing: 16) {
        // High confidence command
        VoiceCommandBubble(
            command: ProcessedVoiceCommand(
                originalText: "set channel one to minus six dB",
                rcpCommand: RCPCommand(
                    command: "set MIXER:Current/Channel/Fader/Level 0 0 -600",
                    description: "Set channel 1 to -6.0 dB",
                    confidence: 0.9,
                    category: .channelFader
                ),
                confidence: 0.9
            ),
            onTap: { print("High confidence tap") }
        )
        
        // Medium confidence command
        VoiceCommandBubble(
            command: ProcessedVoiceCommand(
                originalText: "mute the kick drum",
                rcpCommand: RCPCommand(
                    command: "set MIXER:Current/Channel/Mute 0 0 1",
                    description: "Mute channel 1 (kick drum)",
                    confidence: 0.7,
                    category: .channelMute
                ),
                confidence: 0.7
            ),
            onTap: { print("Medium confidence tap") }
        )
        
        // Low confidence command with metadata
        VoiceCommandBubble(
            command: ProcessedVoiceCommand(
                originalText: "recall scene three",
                rcpCommand: RCPCommand(
                    command: "set MIXER:Current/Scene/Recall 2",
                    description: "Recall scene 3",
                    confidence: 0.5,
                    category: .scene
                ),
                confidence: 0.5,
                processingMetadata: ProcessingMetadata(
                    processingTimeMs: 45.2,
                    processorUsed: "scene_processor",
                    usedContext: false,
                    isCompoundCommand: false,
                    processingNotes: ["Low confidence due to unclear speech"]
                )
            ),
            showMetadata: true,
            onTap: { print("Low confidence tap") }
        )
        
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}