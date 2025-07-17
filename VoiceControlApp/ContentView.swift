import SwiftUI
import FirebaseAuth
#if DEBUG
import HotSwiftUI
#endif

// MARK: - ContentView (Entry Point)
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    #if DEBUG
    @ObservedObject var iO = injectionObserver
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
        .eraseToAnyView()
        #endif
    }
}

#if DEBUG
// MARK: - Hot Reloading Support  
let injectionObserver = InjectionObserver.shared
#endif

// MARK: - Preview
#Preview {
    ContentView()
}