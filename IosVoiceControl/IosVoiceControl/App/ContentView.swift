import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        NavigationStack {
            Group {
                switch authManager.authState {
                case .unauthenticated:
                    AuthenticationView()
                case .authenticating:
                    ProgressView("Authenticating...")
                        .scaleEffect(1.2)
                case .authenticated:
                    MainAppView()
                case .requiresBiometric:
                    BiometricAuthView()
                case .error(let error):
                    ErrorView(error: error)
                }
            }
        }
    }
}

// Main app view for authenticated users
struct MainAppView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            // Voice Control Tab (Future Implementation)
            VoiceControlView()
                .tabItem {
                    Image(systemName: "waveform.circle")
                    Text("Voice Control")
                }
            
            // Account Tab
            AccountManagementView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Account")
                }
        }
    }
}

// Home view for the main app
struct HomeView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(spacing: 8) {
                    Text("Welcome to Voice Control!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if let user = authManager.currentUser {
                        Text("Hello, \(user.displayName ?? "User")!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                
                // Feature Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    FeatureCard(
                        icon: "waveform.circle.fill",
                        title: "Voice Commands",
                        description: "Control your device with voice",
                        color: .blue
                    )
                    
                    FeatureCard(
                        icon: "shield.checkered",
                        title: "Secure Access",
                        description: "Biometric authentication",
                        color: .green
                    )
                    
                    FeatureCard(
                        icon: "gear.circle.fill",
                        title: "Settings",
                        description: "Customize your experience",
                        color: .orange
                    )
                    
                    FeatureCard(
                        icon: "info.circle.fill",
                        title: "Help & Support",
                        description: "Get assistance",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Quick Actions
                VStack(spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Start Voice Control") {
                            // Future implementation
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("View Settings") {
                            // Navigate to settings
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Voice Control")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Voice Control view placeholder
struct VoiceControlView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Voice Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Advanced voice control features will be available in a future update.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Voice Control")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Feature card component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct BiometricAuthView: View {
    var body: some View {
        VStack {
            Text("Biometric Authentication Required")
                .font(.title2)
                .padding()
            
            // This will be implemented in biometric auth task
            Button("Use Biometric Authentication") {
                // Biometric auth logic
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ErrorView: View {
    let error: AuthenticationError
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Authentication Error")
                .font(.title2)
                .padding(.top)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                // Reset error state
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
}