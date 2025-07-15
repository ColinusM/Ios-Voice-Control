import SwiftUI
import Firebase
import GoogleSignIn

// Import authentication modules
import Foundation
#if DEBUG
import InjectionNext
#endif

@main
struct VoiceControlAppApp: App {
    
    init() {
        FirebaseApp.configure()
        
        // Configure Google Sign-In for enterprise security
        GoogleSignInService.configure()
        
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