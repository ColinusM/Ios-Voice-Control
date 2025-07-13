import SwiftUI

@main
struct IosVoiceControlApp: App {
    // CRITICAL: Use @UIApplicationDelegateAdaptor for AppDelegate integration
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // PATTERN: Create @StateObject authManager for app-wide auth state
    @State private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
        }
    }
}