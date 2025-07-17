import SwiftUI
import FirebaseAuth
#if DEBUG
// import HotSwiftUI  // Temporarily disabled
#endif

// MARK: - ContentView (Entry Point)
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    #if DEBUG
    // @ObservedObject var iO = injectionObserver  // Temporarily disabled
    #endif
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .authenticated:
                VoiceControlMainView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🎯 SHOWING VoiceControlMainView - Auth state: .authenticated")
                    }
            case .unauthenticated:
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("🔓 SHOWING AuthenticationView - Auth state: .unauthenticated")
                    }
            case .authenticating:
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("⏳ SHOWING AuthenticationView - Auth state: .authenticating")
                    }
            case .error(let message):
                AuthenticationView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("❌ SHOWING AuthenticationView - Auth state: .error(\(message))")
                    }
            case .requiresBiometric:
                AuthenticationView()
                    .environmentObject(authManager)
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