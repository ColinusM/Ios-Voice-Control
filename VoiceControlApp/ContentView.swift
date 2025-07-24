import SwiftUI
import FirebaseAuth
#if DEBUG
// import HotSwiftUI  // Temporarily disabled
#endif


// MARK: - ContentView (Entry Point)
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    #if DEBUG
    // @ObservedObject var iO = injectionObserver  // Temporarily disabled
    #endif
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .authenticated, .guest:
                // Both authenticated and guest users can access main app (Apple Guideline 2.1)
                VoiceControlMainView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        print("🎯 SHOWING VoiceControlMainView - Auth state: \(authManager.authState)")
                    }
            case .unauthenticated:
                // Show welcome screen with guest/sign-in options
                WelcomeView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        print("🔓 SHOWING WelcomeView - Auth state: .unauthenticated")
                    }
            case .authenticating:
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        print("⏳ SHOWING AuthenticationView - Auth state: .authenticating")
                    }
            case .error(let message):
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        print("❌ SHOWING AuthenticationView - Auth state: .error(\(message))")
                    }
            case .requiresBiometric:
                AuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(subscriptionManager)
                    .onAppear {
                        print("🔒 SHOWING AuthenticationView - Auth state: .requiresBiometric")
                    }
            }
        }
        .onAppear {
            print("📱 ContentView appeared - Current auth state: \(authManager.authState)")
        }
        #if DEBUG
        // .eraseToAnyView()  // Temporarily disabled
        #endif
    }
}

#if DEBUG
// MARK: - Hot Reloading Support  
// let injectionObserver = InjectionObserver.shared  // Temporarily disabled
#endif

// MARK: - Preview
#Preview {
    ContentView()
}