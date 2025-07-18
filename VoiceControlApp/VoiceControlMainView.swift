import SwiftUI
import FirebaseAuth
import AVFoundation

// MARK: - Voice Control Main App
struct VoiceControlMainView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var assemblyAIStreamer = AssemblyAIStreamer()
    @State private var isRecording: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with user info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voice Control")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let user = authManager.currentUser {
                            let firstName = user.displayName?.split(separator: " ").first.map(String.init) ?? "User"
                            Text("Welcome, \(firstName)")
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
                
                Spacer()
                
                // Main Speech Text Box
                VStack(spacing: 16) {
                    HStack {
                        Text("Speech Recognition")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Clear button
                        if !assemblyAIStreamer.transcriptionText.isEmpty {
                            Button(action: {
                                print("🗑️ Clicked on bin")
                                assemblyAIStreamer.clearTranscriptionText()
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    ScrollView {
                        Text(assemblyAIStreamer.transcriptionText.isEmpty ? "Tap the microphone to start speaking..." : assemblyAIStreamer.transcriptionText)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(assemblyAIStreamer.transcriptionText.isEmpty ? .secondary : .primary)
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
                
                // Microphone Button
                Button(action: {
                    toggleRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 80, height: 80)
                            .shadow(radius: isRecording ? 8 : 4)
                        
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                
                Spacer()
                
                // Status Text
                VStack(spacing: 4) {
                    Text(getStatusText())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let errorMessage = assemblyAIStreamer.errorMessage {
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
        .onAppear {
            print("✅ VoiceControlMainView appeared - User: \(authManager.currentUser?.email ?? "Unknown")")
        }
        .onChange(of: assemblyAIStreamer.isStreaming) { isStreamingActive in
            // Sync UI recording state with actual streaming state
            DispatchQueue.main.async {
                isRecording = isStreamingActive
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            // Stop recording
            assemblyAIStreamer.stopStreaming()
            isRecording = false
            print("🛑 Stopped recording")
        } else {
            // Start recording with explicit permission check
            print("🎤 User tapped microphone - checking permissions...")
            
            Task {
                // Force permission request BEFORE attempting to record
                let audioManager = AudioManager()
                let hasPermission = await audioManager.requestMicrophonePermission()
                
                await MainActor.run {
                    if hasPermission {
                        print("🎤 Permission granted - starting recording")
                        isRecording = true
                        
                        Task {
                            await assemblyAIStreamer.startStreaming()
                            
                            // Update UI state based on actual streaming state
                            await MainActor.run {
                                if !assemblyAIStreamer.isStreaming {
                                    // If streaming failed, reset recording state
                                    isRecording = false
                                }
                            }
                        }
                    } else {
                        print("🎤 Permission denied - cannot start recording")
                        // Show error to user
                        assemblyAIStreamer.errorMessage = "Microphone permission required. Please enable in Settings > Privacy & Security > Microphone > VoiceControlApp"
                    }
                }
            }
        }
    }
    
    private func getStatusText() -> String {
        switch assemblyAIStreamer.connectionState {
        case .disconnected:
            return "Tap microphone to speak"
        case .connecting:
            return "🔌 Connecting..."
        case .connected:
            return "🎤 Preparing to listen..."
        case .streaming:
            return "🎤 Listening..."
        case .gracefulShutdown:
            return "Stopping..."
        case .error(_):
            return "❌ Connection error"
        }
    }
}

#Preview {
    VoiceControlMainView()
}