import SwiftUI

// MARK: - Main Authentication Container View

struct AuthenticationView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var selectedTab: AuthTab = .signIn
    @State private var showingPasswordReset = false
    
    enum AuthTab: CaseIterable {
        case signIn
        case signUp
        
        var title: String {
            switch self {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Sign Up"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                authHeaderView
                
                // Tab Selection
                authTabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    SignInView(showPasswordReset: $showingPasswordReset)
                        .tag(AuthTab.signIn)
                    
                    SignUpView()
                        .tag(AuthTab.signUp)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
    }
    
    // MARK: - Header View
    
    private var authHeaderView: some View {
        VStack(spacing: 16) {
            // App Icon/Logo placeholder
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            VStack(spacing: 8) {
                Text("Voice Control")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Secure authentication for your voice control experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Tab Selector
    
    private var authTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.title)
                            .font(.headline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview

#Preview {
    AuthenticationView()
        .environment(AuthenticationManager())
}