import Foundation
import SwiftUI
import FirebaseAuth

// MARK: - Authentication State Manager with ObservableObject Pattern

class AuthenticationManager: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let firebaseAuthService = FirebaseAuthService()
    
    // MARK: - Initialization
    
    init() {
        setupAuthListener()
        Task {
            await checkPersistedSession()
        }
    }
    
    deinit {
        removeAuthListener()
    }
    
    // MARK: - Firebase Auth Listener Setup
    
    private func setupAuthListener() {
        // CRITICAL: Use weak self to prevent retain cycles
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                // CRITICAL: Update UI on main thread
                self?.handleAuthStateChange(user)
            }
        }
    }
    
    private func removeAuthListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
    }
    
    @MainActor
    private func handleAuthStateChange(_ firebaseUser: FirebaseAuth.User?) {
        if let firebaseUser = firebaseUser {
            currentUser = User.from(firebaseUser: firebaseUser)
            
            // Check if biometric authentication is required
            if shouldRequireBiometricAuth() {
                authState = .requiresBiometric
            } else {
                authState = .authenticated
            }
            
            // Persist user session
            Task {
                await persistUserSession()
            }
        } else {
            currentUser = nil
            authState = .unauthenticated
            clearPersistedSession()
        }
        
        isLoading = false
        errorMessage = nil
    }
    
    // MARK: - Authentication Methods
    
    @MainActor
    func signIn(email: String, password: String) async {
        authState = .authenticating
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await firebaseAuthService.signIn(email: email, password: password)
            // State change will be handled by the listener
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            authState = .error(authError)
            errorMessage = authError.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func signUp(email: String, password: String, displayName: String?) async {
        authState = .authenticating
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await firebaseAuthService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            // State change will be handled by the listener
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            authState = .error(authError)
            errorMessage = authError.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            // Sign out from Firebase
            try await firebaseAuthService.signOut()
            
            // Sign out from social providers
            GoogleSignInService.signOut()
            
            // Clear persisted session
            clearPersistedSession()
            
            #if DEBUG
            print("✅ AuthenticationManager: Complete sign-out successful")
            #endif
            
            // State change will be handled by the listener
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            authState = .error(authError)
            errorMessage = authError.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func resetPassword(email: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseAuthService.resetPassword(email: email)
            isLoading = false
            return true
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            errorMessage = authError.localizedDescription
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func deleteAccount() async -> Bool {
        guard currentUser != nil else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseAuthService.deleteAccount()
            // Clear persisted session
            clearPersistedSession()
            // State change will be handled by the listener
            isLoading = false
            return true
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            authState = .error(authError)
            errorMessage = authError.localizedDescription
            isLoading = false
            return false
        }
    }
    
    @MainActor
    func sendEmailVerification() async -> Bool {
        guard let currentUser = currentUser else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseAuthService.sendEmailVerification()
            isLoading = false
            return true
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            errorMessage = authError.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Social Authentication
    
    @MainActor
    func signInWithGoogle() async {
        authState = .authenticating
        isLoading = true
        errorMessage = nil
        
        do {
            let result = await GoogleSignInService.signIn()
            
            switch result {
            case .success(let socialAuthResult):
                // Convert to our User model and update state
                currentUser = socialAuthResult.toUser()
                
                // Check if biometric authentication is required
                if shouldRequireBiometricAuth() {
                    authState = .requiresBiometric
                } else {
                    authState = .authenticated
                }
                
                // Persist user session
                await persistUserSession()
                
                #if DEBUG
                print("✅ AuthenticationManager: Google Sign-In successful")
                #endif
                
            case .failure(let socialError):
                let authError = AuthenticationError.from(socialError)
                authState = .error(authError)
                errorMessage = authError.localizedDescription
                
                #if DEBUG
                print("❌ AuthenticationManager: Google Sign-In failed - \(socialError.localizedDescription)")
                #endif
            }
        } catch {
            let authError = AuthenticationError.fromFirebaseError(error)
            authState = .error(authError)
            errorMessage = authError.localizedDescription
        }
        
        isLoading = false
    }
    
    
    // MARK: - Session Persistence
    
    private func checkPersistedSession() async {
        // Check if user has a valid session in Keychain
        do {
            let persistedUser: User = try KeychainService.retrieve("current_user", as: User.self)
            // Verify the session is still valid with Firebase
            if Auth.auth().currentUser != nil {
                await MainActor.run {
                    currentUser = persistedUser
                    authState = shouldRequireBiometricAuth() ? .requiresBiometric : .authenticated
                }
            } else {
                // Session expired, clear persisted data
                clearPersistedSession()
            }
        } catch {
            // No persisted session or keychain error
            clearPersistedSession()
            
            // DEVELOPMENT: Auto-login for testing in simulator
            #if DEBUG && targetEnvironment(simulator)
            await autoLoginForTesting()
            #endif
        }
    }
    
    #if DEBUG && targetEnvironment(simulator)
    private func autoLoginForTesting() async {
        // Auto-login with test credentials for faster development
        let testEmail = "colin.mignot1@gmail.com"
        let testPassword = "Licofeuh7."
        
        print("🔧 DEV MODE: Auto-login attempt with test credentials")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let authResult = try await firebaseAuthService.signIn(email: testEmail, password: testPassword)
            // The authentication state will be handled by the Firebase auth listener
            await MainActor.run {
                isLoading = false
                print("✅ DEV MODE: Auto-login successful")
            }
        } catch {
            await MainActor.run {
                isLoading = false
                print("⚠️ DEV MODE: Auto-login failed, will show login screen")
            }
        }
    }
    #endif
    
    private func persistUserSession() async {
        guard let user = currentUser else { return }
        
        do {
            try KeychainService.save(user, for: "current_user")
            
            // Store Firebase ID token for backend authentication
            if let firebaseUser = Auth.auth().currentUser {
                let idToken = try await firebaseUser.getIDToken()
                try KeychainService.save(idToken, for: "firebase_id_token")
            }
        } catch {
            print("Failed to persist user session: \(error)")
        }
    }
    
    private func clearPersistedSession() {
        try? KeychainService.delete("current_user")
        try? KeychainService.delete("firebase_id_token")
    }
    
    // MARK: - Biometric Authentication
    
    private func shouldRequireBiometricAuth() -> Bool {
        // Check if biometric auth is enabled in user preferences
        // This would be configurable by the user
        return UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
    }
    
    @MainActor
    func completeBiometricAuth() {
        if currentUser != nil {
            authState = .authenticated
        }
    }
    
    // MARK: - Error Handling
    
    @MainActor
    func clearError() {
        errorMessage = nil
        if case .error = authState {
            authState = .unauthenticated
        }
    }
    
    // MARK: - Token Management
    
    func getCurrentIDToken() async throws -> String? {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        return try await firebaseUser.getIDToken()
    }
    
    func refreshIDToken() async throws -> String? {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        let idToken = try await firebaseUser.getIDToken(forcingRefresh: true)
        
        // Update stored token
        try KeychainService.save(idToken, for: "firebase_id_token")
        
        return idToken
    }
}