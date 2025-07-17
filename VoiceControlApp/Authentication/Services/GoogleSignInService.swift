import Foundation
import SwiftUI
import GoogleSignIn
import FirebaseAuth

// MARK: - Google Sign-In Service

/// Enterprise-grade Google Sign-In service with OAuth 2.0 + PKCE security
class GoogleSignInService {
    
    // MARK: - Configuration
    
    // Client ID will be read from GoogleService-Info.plist
    
    // MARK: - Initialization
    
    private static var isConfigured = false
    
    static func configure() {
        guard !isConfigured else { return }
        
        #if targetEnvironment(simulator)
        #if DEBUG
        print("⚠️ GoogleSignInService: Running in simulator - skipping Google Sign-In configuration")
        #endif
        isConfigured = true
        return
        #endif
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["REVERSED_CLIENT_ID"] as? String else {
            #if DEBUG
            print("❌ GoogleSignInService: GoogleService-Info.plist not found or REVERSED_CLIENT_ID missing")
            #endif
            return
        }
        
        #if DEBUG
        print("🔧 GoogleSignInService: Starting configuration...")
        print("   Client ID: \(clientId)")
        #endif
        
        // Configure Google Sign-In with client ID from Firebase configuration
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        isConfigured = true
        
        #if DEBUG
        print("✅ GoogleSignInService: Configuration completed successfully")
        #endif
    }
    
    // MARK: - Sign In
    
    /// Initiates Google Sign-In flow with enterprise security (OAuth 2.0 + PKCE)
    /// - Returns: Result containing social auth result or error
    static func signIn() async -> Result<SocialAuthResult, SocialAuthError> {
        #if DEBUG
        print("🔵 GoogleSignInService: Initiating sign-in flow")
        #endif
        
        #if targetEnvironment(simulator)
        #if DEBUG
        print("⚠️ GoogleSignInService: Running in simulator - returning mock failure")
        #endif
        return .failure(.providerConfigurationMissing(.google))
        #endif
        
        // Ensure Google Sign-In is configured
        configure()
        
        guard GIDSignIn.sharedInstance.configuration != nil else {
            #if DEBUG
            print("❌ GoogleSignInService: Not configured - call configure() first")
            #endif
            return .failure(.providerConfigurationMissing(.google))
        }
        
        // Get the presenting view controller using external user agent (enterprise security requirement)
        guard let presentingViewController = await getPresentingViewController() else {
            return .failure(.invalidClientConfiguration(.google))
        }
        
        return await withCheckedContinuation { continuation in
            // Use external user agent (SFSafariViewController) - CRITICAL for enterprise security
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    let socialError = mapGoogleError(error)
                    #if DEBUG
                    print("❌ GoogleSignInService: Sign-in failed - \(socialError.localizedDescription)")
                    #endif
                    continuation.resume(returning: .failure(socialError))
                    return
                }
                
                guard let result = result else {
                    continuation.resume(returning: .failure(.authorizationFailed(.google)))
                    return
                }
                
                // Extract Google user data
                let googleUser = result.user
                guard let idToken = googleUser.idToken?.tokenString else {
                    continuation.resume(returning: .failure(.tokenExchangeFailed(.google)))
                    return
                }
                
                // Create social auth credentials with enterprise security
                let credentials = SocialCredentials(
                    idToken: idToken,
                    accessToken: googleUser.accessToken.tokenString,
                    provider: .google,
                    expirationDate: googleUser.idToken?.expirationDate
                )
                
                // Create social user profile
                let profile = SocialUserProfile.fromGoogle(
                    userId: googleUser.userID,
                    email: googleUser.profile?.email,
                    displayName: googleUser.profile?.name,
                    imageURL: googleUser.profile?.imageURL(withDimension: 120)
                )
                
                // Authenticate with Firebase using Google credentials
                Task {
                    do {
                        let firebaseCredential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: googleUser.accessToken.tokenString)
                        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                        
                        let socialAuthResult = SocialAuthResult(
                            provider: .google,
                            firebaseUser: authResult.user,
                            profile: profile,
                            credentials: credentials,
                            isNewUser: authResult.additionalUserInfo?.isNewUser ?? false
                        )
                        
                        #if DEBUG
                        print("✅ GoogleSignInService: Sign-in successful for \(profile.email ?? "unknown")")
                        #endif
                        
                        continuation.resume(returning: .success(socialAuthResult))
                    } catch {
                        #if DEBUG
                        print("❌ GoogleSignInService: Firebase authentication failed - \(error.localizedDescription)")
                        #endif
                        continuation.resume(returning: .failure(.firebaseSignInFailed(underlying: error)))
                    }
                }
            }
        }
    }
    
    /// Signs out the current Google user
    static func signOut() {
        #if DEBUG
        print("🔵 GoogleSignInService: Signing out Google user")
        #endif
        
        GIDSignIn.sharedInstance.signOut()
        
        #if DEBUG
        print("✅ GoogleSignInService: Sign-out completed")
        #endif
    }
    
    /// Restores the user's previous sign-in state (for automatic re-authentication)
    static func restorePreviousSignIn() async -> Result<SocialAuthResult?, SocialAuthError> {
        #if DEBUG
        print("🔵 GoogleSignInService: Attempting to restore previous sign-in")
        #endif
        
        #if targetEnvironment(simulator)
        #if DEBUG
        print("⚠️ GoogleSignInService: Running in simulator - no previous sign-in to restore")
        #endif
        return .success(nil)
        #endif
        
        // Ensure Google Sign-In is configured
        configure()
        
        guard GIDSignIn.sharedInstance.configuration != nil else {
            return .failure(.providerConfigurationMissing(.google))
        }
        
        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let error = error {
                    let socialError = mapGoogleError(error)
                    #if DEBUG
                    print("⚠️ GoogleSignInService: Restore failed - \(socialError.localizedDescription)")
                    #endif
                    continuation.resume(returning: .failure(socialError))
                    return
                }
                
                guard let user = user,
                      let idToken = user.idToken?.tokenString else {
                    #if DEBUG
                    print("ℹ️ GoogleSignInService: No previous sign-in to restore")
                    #endif
                    continuation.resume(returning: .success(nil))
                    return
                }
                
                // Create social auth credentials
                let credentials = SocialCredentials(
                    idToken: idToken,
                    accessToken: user.accessToken.tokenString,
                    provider: .google,
                    expirationDate: user.idToken?.expirationDate
                )
                
                // Create social user profile
                let profile = SocialUserProfile.fromGoogle(
                    userId: user.userID,
                    email: user.profile?.email,
                    displayName: user.profile?.name,
                    imageURL: user.profile?.imageURL(withDimension: 120)
                )
                
                // Re-authenticate with Firebase
                Task {
                    do {
                        let firebaseCredential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                        
                        let socialAuthResult = SocialAuthResult(
                            provider: .google,
                            firebaseUser: authResult.user,
                            profile: profile,
                            credentials: credentials,
                            isNewUser: false
                        )
                        
                        #if DEBUG
                        print("✅ GoogleSignInService: Previous sign-in restored for \(profile.email ?? "unknown")")
                        #endif
                        
                        continuation.resume(returning: .success(socialAuthResult))
                    } catch {
                        #if DEBUG
                        print("❌ GoogleSignInService: Firebase re-authentication failed - \(error.localizedDescription)")
                        #endif
                        continuation.resume(returning: .failure(.firebaseSignInFailed(underlying: error)))
                    }
                }
            }
        }
    }
    
    // MARK: - URL Handling
    
    /// Handles incoming URL for Google Sign-In (OAuth redirect)
    /// - Parameter url: The URL to handle
    /// - Returns: True if the URL was handled, false otherwise
    static func handleURL(_ url: URL) -> Bool {
        #if DEBUG
        print("🔵 GoogleSignInService: Handling OAuth redirect URL")
        print("   URL: \(url)")
        #endif
        
        let handled = GIDSignIn.sharedInstance.handle(url)
        
        #if DEBUG
        if handled {
            print("✅ GoogleSignInService: URL handled successfully")
        } else {
            print("⚠️ GoogleSignInService: URL not recognized")
        }
        #endif
        
        return handled
    }
    
    // MARK: - Helper Methods
    
    /// Gets the presenting view controller for Google Sign-In (external user agent)
    private static func getPresentingViewController() async -> UIViewController? {
        return await MainActor.run {
            // Get the root view controller from the key window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                #if DEBUG
                print("❌ GoogleSignInService: No presenting view controller available")
                #endif
                return nil
            }
            
            // Find the topmost presented view controller
            var presentingViewController = rootViewController
            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }
            
            return presentingViewController
        }
    }
    
    /// Maps Google Sign-In errors to SocialAuthError
    private static func mapGoogleError(_ error: Error) -> SocialAuthError {
        let nsError = error as NSError
        
        // Check for Google Sign-In specific error codes
        if nsError.domain == "com.google.GIDSignIn" {
            switch nsError.code {
            case -1: // User cancelled
                return .userCancelled(.google)
            case -2: // Keychain error
                return .keychainAccessFailed
            case -3: // No current user
                return .googleAccountNotFound
            case -4: // Sign-in was interrupted
                return .authorizationFailed(.google)
            case -5: // Sign-in is currently in progress
                return .internalError(description: "Sign-in already in progress")
            default:
                return .authorizationFailed(.google)
            }
        }
        
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(underlying: error)
            case .timedOut:
                return .requestTimeout
            default:
                return .networkError(underlying: error)
            }
        }
        
        return .unknown(underlying: error)
    }
}

// MARK: - Token Management

extension GoogleSignInService {
    
    /// Refreshes the Google access token
    static func refreshToken() async -> Result<SocialCredentials, SocialAuthError> {
        #if DEBUG
        print("🔵 GoogleSignInService: Refreshing access token")
        #endif
        
        #if targetEnvironment(simulator)
        #if DEBUG
        print("⚠️ GoogleSignInService: Running in simulator - cannot refresh token")
        #endif
        return .failure(.googleAccountNotFound)
        #endif
        
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            return .failure(.googleAccountNotFound)
        }
        
        return await withCheckedContinuation { continuation in
            currentUser.refreshTokensIfNeeded { user, error in
                if let error = error {
                    let socialError = mapGoogleError(error)
                    #if DEBUG
                    print("❌ GoogleSignInService: Token refresh failed - \(socialError.localizedDescription)")
                    #endif
                    continuation.resume(returning: .failure(socialError))
                    return
                }
                
                guard let user = user,
                      let idToken = user.idToken?.tokenString else {
                    continuation.resume(returning: .failure(.tokenRefreshFailed(.google)))
                    return
                }
                
                let credentials = SocialCredentials(
                    idToken: idToken,
                    accessToken: user.accessToken.tokenString,
                    provider: .google,
                    expirationDate: user.idToken?.expirationDate
                )
                
                #if DEBUG
                print("✅ GoogleSignInService: Token refreshed successfully")
                #endif
                
                continuation.resume(returning: .success(credentials))
            }
        }
    }
    
    /// Checks if the current Google user is signed in
    static var isSignedIn: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return GIDSignIn.sharedInstance.currentUser != nil
        #endif
    }
    
    /// Gets the current Google user's email if available
    static var currentUserEmail: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return GIDSignIn.sharedInstance.currentUser?.profile?.email
        #endif
    }
}
