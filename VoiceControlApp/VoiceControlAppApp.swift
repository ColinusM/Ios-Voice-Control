import SwiftUI
import Firebase
#if DEBUG
import InjectionNext
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
        }
    }
}