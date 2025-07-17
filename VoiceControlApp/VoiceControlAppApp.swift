import SwiftUI
import Firebase
import GoogleSignIn

// Import authentication modules
import Foundation
#if DEBUG
// import InjectionNext  // Temporarily disabled
#endif

@main
struct VoiceControlAppApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Remove manual bundle loading - using HotSwiftUI package instead
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle OAuth redirect URLs for Google Sign-In
                    _ = GoogleSignInService.handleURL(url)
                    print("URL opened: \(url)")
                }
        }
    }
}