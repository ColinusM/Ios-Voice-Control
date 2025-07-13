import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // CRITICAL: Configure Firebase before any other Firebase calls
        FirebaseApp.configure()
        
        // PATTERN: Setup any additional Firebase services here
        // Future: Analytics.logEvent() configuration
        
        #if DEBUG
        // InjectionIII for hot reloading during development
        Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
        #endif
        
        return true
    }
}