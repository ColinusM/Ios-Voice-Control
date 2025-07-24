import SwiftUI
import FirebaseAuth
import AVFoundation
import Speech
import Combine

// MARK: - Voice Control Main App
struct VoiceControlMainView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var speechManager = SpeechRecognitionManager()
    @State private var isRecording: Bool = false
    @State private var orbitalAngle: Double = 0.0
    @State private var showSubscriptionView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with user info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voice Control")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // User greeting
                        if let user = authManager.currentUser {
                            let firstName = user.displayName?.split(separator: " ").first.map(String.init) ?? "User"
                            Text("Welcome, \(firstName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if authManager.authState == .guest {
                            Text("Guest Mode")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Sign Out Button (compact)
                    Button(action: {
                        Task { await authManager.signOut() }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Usage Indicator for Guest Users
                if authManager.authState == .guest, let guestUser = authManager.guestUser {
                    UsageIndicatorView(
                        guestUser: guestUser,
                        subscriptionState: subscriptionManager.subscriptionState,
                        onUpgradePressed: {
                            showSubscriptionView = true
                        }
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Main Speech Text Box
                VStack(spacing: 16) {
                    HStack {
                        Text("Speech Recognition")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Clear button
                        if !speechManager.transcriptionText.isEmpty {
                            Button(action: {
                                print("🗑️ Clicked on bin")
                                speechManager.clearTranscriptionText()
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    ScrollView {
                        Text(speechManager.transcriptionText.isEmpty ? "Tap the microphone to start speaking..." : speechManager.transcriptionText)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(speechManager.transcriptionText.isEmpty ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecording ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Orbital Toggle System (Earth-Moon UI)
                ZStack {
                    // Main Record Button (Earth)
                    RecordButton(
                        isRecording: speechManager.isRecording,
                        mode: speechManager.activeEngine,
                        isSwitchingEngines: speechManager.isSwitchingEngines,
                        connectionState: speechManager.connectionState,
                        onTap: { toggleRecording() }
                    )
                    
                    // Orbital Toggle Button (Moon)
                    OrbitalToggleButton(
                        angle: orbitalAngle,
                        currentMode: speechManager.activeEngine,
                        isSwitchingEngines: speechManager.isSwitchingEngines,
                        onToggle: { newMode in
                            switchToEngineSync(newMode)
                        }
                    )
                }
                .frame(height: 160) // Accommodate orbital radius
                
                Spacer()
                
                // Status Text
                VStack(spacing: 4) {
                    Text(getStatusText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Engine indicator
                    Text("Engine: \(speechManager.activeEngine.displayName)")
                        .font(.caption)
                        .foregroundColor(speechManager.activeEngine.color)
                        .fontWeight(.medium)
                    
                    if let errorMessage = speechManager.errorMessage {
                        Text("Error: \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
                .environmentObject(subscriptionManager)
                .environmentObject(authManager)
        }
        .onAppear {
            print("✅ VoiceControlMainView appeared - User: \(authManager.currentUser?.email ?? "Unknown")")
            
            // Configure speech manager with dependency injection
            speechManager.configure(subscriptionManager: subscriptionManager, authManager: authManager)
            
            // Initialize orbital position
            orbitalAngle = speechManager.activeEngine.orbitalAngle
        }
        .onChange(of: speechManager.isRecording) { oldValue, newValue in
            // Sync UI recording state with actual streaming state
            DispatchQueue.main.async {
                isRecording = newValue
            }
        }
        .onChange(of: speechManager.activeEngine) { oldValue, newValue in
            // Update orbital angle when engine changes
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                orbitalAngle = newValue.orbitalAngle
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .environmentRecommendationUpdated)) { notification in
            handleEnvironmentRecommendation(notification)
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            // Stop recording
            speechManager.stopRecording()
            isRecording = false
            print("🛑 Stopped recording with \(speechManager.activeEngine.displayName)")
        } else {
            // Start recording with explicit permission check
            print("🎤 User tapped microphone - checking permissions...")
            
            Task {
                // Force permission request BEFORE attempting to record
                let audioManager = AudioManager()
                let hasPermission = await audioManager.requestMicrophonePermission()
                
                if hasPermission {
                    print("🎤 Permission granted - starting recording with \(speechManager.activeEngine.displayName)")
                    
                    await MainActor.run {
                        isRecording = true
                    }
                    
                    await speechManager.startRecording()
                    
                    // Update UI state based on actual streaming state
                    await MainActor.run {
                        if !speechManager.isRecording {
                            // If streaming failed, reset recording state
                            isRecording = false
                        }
                    }
                } else {
                    print("🎤 Permission denied - cannot start recording")
                    // Show error to user
                    speechManager.errorMessage = "Microphone permission required. Please enable in Settings > Privacy & Security > Microphone > VoiceControlApp"
                }
            }
        }
    }
    
    private func getStatusText() -> String {
        if speechManager.isSwitchingEngines {
            return "🔄 Switching engines..."
        }
        
        switch speechManager.connectionState {
        case .disconnected:
            return "Tap microphone to speak"
        case .connecting:
            return "🔌 Connecting..."
        case .connected:
            return "🎤 Preparing to listen..."
        case .streaming:
            return "🎤 Listening..."
        case .error(let streamingError):
            switch streamingError {
            case .usageLimitReached:
                return "⚠️ Usage limit reached"
            case .authenticationFailed:
                return "❌ Authentication failed"
            case .networkError:
                return "❌ Network error" 
            case .connectionFailed(_):
                return "❌ Connection error"
            case .unknownError(_):
                return "❌ Unknown error"
            }
        }
    }
    
    // MARK: - Engine Switching
    
    private func switchToEngineSync(_ newEngine: SpeechRecognitionMode) {
        print("🔄 User requested switch to \(newEngine.displayName)")
        
        // Animate orbital position change
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            orbitalAngle = newEngine.orbitalAngle
        }
        
        // Perform engine switch asynchronously
        Task {
            await speechManager.switchEngine(to: newEngine)
            print("✅ Engine switch completed to \(newEngine.displayName)")
        }
    }
    
    private func switchToEngine(_ newEngine: SpeechRecognitionMode) async {
        print("🔄 User requested switch to \(newEngine.displayName)")
        
        // Animate orbital position change
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            orbitalAngle = newEngine.orbitalAngle
        }
        
        // Perform engine switch
        await speechManager.switchEngine(to: newEngine)
        
        print("✅ Engine switch completed to \(newEngine.displayName)")
    }
    
    // MARK: - Environment Recommendations
    
    private func handleEnvironmentRecommendation(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let recommendationString = userInfo["recommendation"] as? String,
              let recommendation = SpeechRecognitionMode(rawValue: recommendationString),
              recommendation != speechManager.activeEngine else {
            return
        }
        
        print("🤖 Environment recommendation: \(recommendation.displayName)")
        
        // For now, just log the recommendation
        // In future, could show subtle UI hint or auto-switch based on user preferences
    }
}

// MARK: - Usage Indicator Component

struct UsageIndicatorView: View {
    let guestUser: GuestUser
    let subscriptionState: SubscriptionState
    let onUpgradePressed: () -> Void
    
    private var progressValue: Double {
        Double(guestUser.totalAPIMinutesUsed) / 60.0
    }
    
    private var progressColor: Color {
        switch guestUser.usageWarningLevel {
        case .none:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Usage Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Free Usage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(guestUser.remainingUsageText)
                        .font(.caption)
                        .foregroundColor(progressColor)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            
            // Warning message for approaching limits
            if guestUser.usageWarningLevel.shouldShowWarning {
                HStack(spacing: 8) {
                    Image(systemName: guestUser.usageWarningLevel == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .foregroundColor(progressColor)
                        .font(.caption)
                    
                    Text(guestUser.usageWarningLevel.warningMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: onUpgradePressed) {
                        Text(guestUser.usageWarningLevel.actionButtonText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(progressColor)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(progressColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(progressColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VoiceControlMainView()
}