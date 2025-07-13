# Google Sign-In Setup Guide

This document provides instructions for enabling Google Sign-In in the iOS Voice Control app.

## Current Status

✅ **Firebase Project**: Configured with Google Sign-In OAuth client  
✅ **Bundle ID**: `com.voicecontrol.app` registered with Google  
✅ **URL Schemes**: Configured in Info.plist  
✅ **Service Implementation**: Prepared for activation  
⏳ **Google Sign-In SDK**: Ready to be added when enabled  

## Prerequisites

1. Firebase project with Google Sign-In authentication enabled
2. OAuth 2.0 client ID configured for iOS app
3. Bundle ID registered: `com.voicecontrol.app`

## Current Configuration

### Firebase Configuration (✅ Complete)

The app is already configured with the necessary Firebase settings:

```yaml
CLIENT_ID: Available in GoogleService-Info.plist
REVERSED_CLIENT_ID: com.googleusercontent.apps.1020288809254-0f690b195cca167b47a9e7
PROJECT_ID: ios-voice-control
BUNDLE_ID: com.voicecontrol.app
```

### URL Schemes (✅ Complete)

Info.plist already contains the required URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>GoogleService</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.1020288809254-0f690b195cca167b47a9e7</string>
        </array>
    </dict>
</array>
```

## Implementation Steps (When Ready)

### 1. Enable Google Sign-In SDK

Add GoogleSignIn to Package.swift dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"), // Add this
    .package(url: "https://github.com/krzysztofzablocki/Inject.git", from: "1.0.0")
],
targets: [
    .target(
        name: "IosVoiceControl",
        dependencies: [
            .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
            .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
            .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"), // Add this
            .product(name: "Inject", package: "Inject")
        ]
    ),
]
```

### 2. Update AppDelegate

Add GoogleSignIn configuration to AppDelegate.swift:

```swift
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist not found or CLIENT_ID missing")
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
```

### 3. Update GoogleSignInService

Uncomment the implementation code in `GoogleSignInService.swift`:

```swift
// Remove #if DEBUG blocks and uncomment actual implementation code
// Replace placeholder returns with real GoogleSignIn SDK calls
```

### 4. Enable Feature Flag

Update Constants.swift:

```swift
struct FeatureFlags {
    static let googleSignInEnabled = true  // Change from false to true
    // ... other flags
}
```

### 5. Update Authentication UI

Add Google Sign-In button to SignInView.swift:

```swift
// Add to SignInView after email/password form
if Constants.FeatureFlags.googleSignInEnabled {
    VStack(spacing: 16) {
        Text("Or")
            .font(.subheadline)
            .foregroundColor(.secondary)
        
        GoogleSignInButton {
            Task {
                await signInWithGoogle()
            }
        }
    }
}
```

### 6. Update AuthenticationManager

Add Google Sign-In methods to AuthenticationManager.swift:

```swift
@MainActor
func signInWithGoogle() async {
    authState = .authenticating
    
    let result = await GoogleSignInService.signIn()
    
    switch result {
    case .success(let googleResult):
        let credentialResult = GoogleSignInService.createFirebaseCredential(from: googleResult)
        
        switch credentialResult {
        case .success(let firebaseCredential):
            // Sign in to Firebase with Google credential
            // Implementation depends on Firebase SDK
            break
        case .failure(let error):
            authState = .error(.unknownError(error.localizedDescription))
        }
        
    case .failure(let error):
        authState = .error(.unknownError(error.localizedDescription))
    }
}
```

## Testing

### Firebase Authentication Console

1. Go to Firebase Console → Authentication → Sign-in method
2. Ensure Google is enabled
3. Verify OAuth client configuration

### URL Scheme Testing

Test URL scheme handling:

```bash
xcrun simctl openurl booted "com.googleusercontent.apps.1020288809254-0f690b195cca167b47a9e7://oauth"
```

### Integration Testing

1. Test sign-in flow with test Google account
2. Verify Firebase user creation
3. Test sign-out and session management
4. Verify profile data integration

## Security Considerations

### Production Checklist

- [ ] Verify OAuth client configuration in Google Cloud Console
- [ ] Enable only necessary OAuth scopes
- [ ] Test with restricted API keys
- [ ] Implement proper error handling for all scenarios
- [ ] Test token refresh and expiration handling

### Privacy

- [ ] Update Privacy Policy to include Google Sign-In data usage
- [ ] Implement proper data handling according to Google's policies
- [ ] Provide clear user consent for data sharing

## Troubleshooting

### Common Issues

1. **"The provided URL scheme is invalid"**
   - Verify URL scheme matches REVERSED_CLIENT_ID exactly
   - Check Info.plist configuration

2. **"No OAuth client found"**
   - Verify CLIENT_ID in GoogleService-Info.plist
   - Check Firebase project configuration

3. **"Invalid client ID"**
   - Ensure bundle ID matches registered OAuth client
   - Verify GoogleService-Info.plist is for correct project

### Debug Mode

Enable debug logging:

```swift
#if DEBUG
GIDSignIn.sharedInstance.configuration?.serverClientID = "your-server-client-id"
#endif
```

## Future Enhancements

- [ ] Add Google account linking for existing users
- [ ] Implement Google profile photo sync
- [ ] Add Google Drive integration (future)
- [ ] Support for Google Workspace accounts

## Support

- [Google Sign-In iOS Documentation](https://developers.google.com/identity/sign-in/ios)
- [Firebase Authentication Documentation](https://firebase.google.com/docs/auth/ios/google-signin)
- [OAuth 2.0 for Mobile & Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)

---

**Note**: Google Sign-In is currently disabled by feature flag. Enable when ready for implementation and testing.