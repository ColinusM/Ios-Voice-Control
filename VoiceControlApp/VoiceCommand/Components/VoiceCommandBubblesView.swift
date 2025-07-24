import SwiftUI

/// Container view for displaying voice command bubbles with animations and scrolling
/// Manages the list of processed commands with smooth transitions and user interactions
struct VoiceCommandBubblesView: View {
    
    // MARK: - Properties
    
    /// The voice command processor that provides the commands
    @ObservedObject var commandProcessor: VoiceCommandProcessor
    
    /// Whether to show processing metadata for debugging
    let showMetadata: Bool
    
    /// Whether to show the clear button
    let showClearButton: Bool
    
    /// Callback for command bubble taps
    let onCommandTap: ((ProcessedVoiceCommand) -> Void)?
    
    /// Callback for command send button taps
    let onCommandSend: ((ProcessedVoiceCommand) -> Void)?
    
    // MARK: - State
    
    @State private var scrollViewID = UUID()
    @State private var showingEmptyState = false
    @State private var animationTrigger = false
    
    // MARK: - Constants
    
    private let bubbleSpacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 16
    private let headerHeight: CGFloat = 40
    private let clearButtonSize: CGFloat = 32
    
    // MARK: - Initialization
    
    init(
        commandProcessor: VoiceCommandProcessor,
        showMetadata: Bool = false,
        showClearButton: Bool = true,
        onCommandTap: ((ProcessedVoiceCommand) -> Void)? = nil,
        onCommandSend: ((ProcessedVoiceCommand) -> Void)? = nil
    ) {
        self.commandProcessor = commandProcessor
        self.showMetadata = showMetadata
        self.showClearButton = showClearButton
        self.onCommandTap = onCommandTap
        self.onCommandSend = onCommandSend
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and controls
            headerView
            
            // Main content area
            ZStack {
                if commandProcessor.recentCommands.isEmpty && !commandProcessor.isProcessing {
                    emptyStateView
                } else {
                    commandBubblesScrollView
                }
                
                // Processing overlay
                if commandProcessor.isProcessing {
                    processingOverlay
                }
                
                // Error overlay
                if let errorMessage = commandProcessor.errorMessage {
                    errorOverlay(errorMessage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: commandProcessor.recentCommands.count)
        .animation(.easeInOut(duration: 0.3), value: commandProcessor.isProcessing)
        .animation(.easeInOut(duration: 0.3), value: commandProcessor.errorMessage)
        .onChange(of: commandProcessor.recentCommands.count) { _ in
            // Trigger animation update when commands change
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                animationTrigger.toggle()
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RCP Commands")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !commandProcessor.recentCommands.isEmpty {
                    Text("\(commandProcessor.recentCommands.count) command\(commandProcessor.recentCommands.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 8) {
                // Processing indicator
                if commandProcessor.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                }
                
                // Clear button
                if showClearButton && !commandProcessor.recentCommands.isEmpty {
                    Button(action: clearCommands) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Clear all commands")
                    .accessibilityHint("Removes all voice commands from the list")
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .background(Color.clear)
        .frame(height: headerHeight)
    }
    
    @ViewBuilder
    private var commandBubblesScrollView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: bubbleSpacing) {
                    ForEach(commandProcessor.recentCommands, id: \.id) { command in
                        VoiceCommandBubble(
                            command: command,
                            showMetadata: showMetadata,
                            onTap: onCommandTap != nil ? { onCommandTap?(command) } : nil,
                            onSend: onCommandSend != nil ? { onCommandSend?(command) } : nil
                        )
                        .id(command.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animationTrigger)
                    }
                    
                    // Bottom spacing for better scrolling experience
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 8)
                .onChange(of: commandProcessor.recentCommands.count) { _ in
                    // Auto-scroll to newest command when new ones are added
                    if let newestCommand = commandProcessor.recentCommands.first {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(newestCommand.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .id(scrollViewID)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Voice Commands")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("Start speaking to see RCP commands appear here")
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Example commands
            VStack(alignment: .leading, spacing: 4) {
                Text("Try saying:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(exampleCommands, id: \.self) { example in
                    Text("• \(example)")
                        .font(.caption)
                        .monospaced()
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .padding(.top, 8)
        }
        .opacity(showingEmptyState ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                showingEmptyState = true
            }
        }
        .onDisappear {
            showingEmptyState = false
        }
    }
    
    @ViewBuilder
    private var processingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("Processing voice command...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8)
    }
    
    @ViewBuilder
    private func errorOverlay(_ errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
            
            Text("Processing Error")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            Button("Dismiss") {
                dismissError()
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .red.opacity(0.2), radius: 8)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Computed Properties
    
    private var exampleCommands: [String] {
        [
            "Set channel 1 to -6 dB",
            "Mute channel 2",
            "Recall scene 3",
            "Channel 4 to unity"
        ]
    }
    
    // MARK: - Private Methods
    
    private func clearCommands() {
        // Generate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            commandProcessor.clearCommands()
            scrollViewID = UUID() // Force scroll view refresh
        }
        
        print("🗑️ Cleared all voice commands")
    }
    
    private func dismissError() {
        // This would ideally be a method on the command processor
        // For now, we'll implement it as a private action
        withAnimation(.easeInOut(duration: 0.3)) {
            // Error dismissal logic would go here
            // Since errorMessage is read-only, the processor would need to handle this
        }
        
        print("❌ Dismissed error message")
    }
}

// MARK: - Filter Options Extension

extension VoiceCommandBubblesView {
    
    /// Version of the view with category filtering
    func filtered(by category: CommandCategory) -> some View {
        return VoiceCommandBubblesView(
            commandProcessor: FilteredCommandProcessor(
                sourceProcessor: commandProcessor,
                filter: { $0.category == category }
            ),
            showMetadata: showMetadata,
            showClearButton: showClearButton,
            onCommandTap: onCommandTap
        )
    }
    
    /// Version of the view with confidence threshold filtering
    func withMinimumConfidence(_ threshold: Double) -> some View {
        return VoiceCommandBubblesView(
            commandProcessor: FilteredCommandProcessor(
                sourceProcessor: commandProcessor,
                filter: { $0.confidence >= threshold }
            ),
            showMetadata: showMetadata,
            showClearButton: showClearButton,
            onCommandTap: onCommandTap
        )
    }
}

// MARK: - Filtered Command Processor

/// Wrapper processor that filters commands based on criteria
/// Used for category filtering and confidence thresholding
@MainActor
private class FilteredCommandProcessor: VoiceCommandProcessor {
    
    private let sourceProcessor: VoiceCommandProcessor
    private let filter: (ProcessedVoiceCommand) -> Bool
    
    init(sourceProcessor: VoiceCommandProcessor, filter: @escaping (ProcessedVoiceCommand) -> Bool) {
        self.sourceProcessor = sourceProcessor
        self.filter = filter
        super.init()
        
        // Mirror source processor state with filtering
        self.recentCommands = sourceProcessor.recentCommands.filter(filter)
        self.isProcessing = sourceProcessor.isProcessing
        self.errorMessage = sourceProcessor.errorMessage
        
        // Observe changes in source processor
        sourceProcessor.$recentCommands
            .map { commands in commands.filter(filter) }
            .assign(to: &$recentCommands)
        
        sourceProcessor.$isProcessing
            .assign(to: &$isProcessing)
        
        sourceProcessor.$errorMessage
            .assign(to: &$errorMessage)
    }
    
    override func processTranscription(_ text: String) {
        // Delegate to source processor
        sourceProcessor.processTranscription(text)
    }
    
    override func clearCommands() {
        // Delegate to source processor
        sourceProcessor.clearCommands()
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        VoiceCommandBubblesView(
            commandProcessor: VoiceCommandProcessor(),
            showMetadata: false,
            onCommandTap: { command in
                print("Command tapped: \(command.rcpCommand.description)")
            }
        )
    }
}