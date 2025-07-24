import SwiftUI

// MARK: - Welcome View (Apple Guideline 2.1 Compliance)

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showAuthSheet = false
    @State private var isEnteringGuestMode = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // App Icon and Title
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.and.mic")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Voice Control")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Professional voice commands for your workflow")
                                .font(.title2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Feature Preview
                    VStack(spacing: 24) {
                        Text("Experience the future of voice control")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 16) {
                            FeatureRow(
                                icon: "mic.circle.fill",
                                title: "Real-time Voice Recognition",
                                description: "Powered by AssemblyAI for accurate transcription"
                            )
                            
                            FeatureRow(
                                icon: "slider.horizontal.3",
                                title: "Mixing Console Control",
                                description: "Professional audio control with voice commands"
                            )
                            
                            FeatureRow(
                                icon: "icloud.and.arrow.up",
                                title: "Cloud Sync",
                                description: "Access your settings across all devices"
                            )
                        }
                    }
                    
                    // Guest vs Sign In Options
                    VStack(spacing: 16) {
                        // Primary CTA: Try Voice Control (Guest Mode)
                        Button(action: enterGuestMode) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Try Voice Control")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("1 hour free • No account required")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                
                                Spacer()
                                
                                if isEnteringGuestMode {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isEnteringGuestMode)
                        
                        // Secondary CTA: Sign In for Full Features
                        Button(action: { showAuthSheet = true }) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sign In for Full Features")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text("Cloud sync • Unlimited usage • Priority support")
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .opacity(0.6)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Usage Comparison
                    ComparisonView()
                        .padding(.horizontal)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Link("Terms", destination: URL(string: "https://voicecontrol.app/terms")!)
                            Link("Privacy", destination: URL(string: "https://voicecontrol.app/privacy")!)
                        }
                        .font(.caption2)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
        }
    }
    
    // MARK: - Actions
    
    private func enterGuestMode() {
        isEnteringGuestMode = true
        
        Task {
            await authManager.enterGuestMode()
            
            await MainActor.run {
                isEnteringGuestMode = false
            }
        }
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

// MARK: - Comparison View

struct ComparisonView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Experience")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Guest Mode Column
                VStack(spacing: 12) {
                    Text("Guest Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ComparisonItem(text: "1 hour free usage", included: true)
                        ComparisonItem(text: "Voice recognition", included: true)
                        ComparisonItem(text: "Basic features", included: true)
                        ComparisonItem(text: "Cloud sync", included: false)
                        ComparisonItem(text: "Unlimited usage", included: false)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Pro Account Column
                VStack(spacing: 12) {
                    HStack {
                        Text("Pro Account")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("$4.99/mo")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    VStack(spacing: 8) {
                        ComparisonItem(text: "Unlimited usage", included: true)
                        ComparisonItem(text: "Voice recognition", included: true)
                        ComparisonItem(text: "All features", included: true)
                        ComparisonItem(text: "Cloud sync", included: true)
                        ComparisonItem(text: "Priority support", included: true)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Comparison Item

struct ComparisonItem: View {
    let text: String
    let included: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundColor(included ? .green : .secondary)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(included ? .primary : .secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
}