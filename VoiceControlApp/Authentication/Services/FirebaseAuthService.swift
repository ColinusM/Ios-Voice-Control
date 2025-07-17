import Foundation
import FirebaseAuth

// MARK: - Firebase Authentication Service with Async/Await

class FirebaseAuthService {
    
    private let auth = Auth.auth()
    
    // MARK: - Sign In Methods
    
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        // CRITICAL: Use async/await, not completion handlers (modern pattern)
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    // MARK: - Sign Up Methods
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws -> AuthDataResult {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        
        // Set display name if provided
        if let displayName = displayName, !displayName.isEmpty {
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        }
        
        // Send email verification automatically
        try await sendEmailVerification()
        
        return authResult
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try auth.signOut()
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Email Verification
    
    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.sendEmailVerification()
    }
    
    func reloadUser() async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.reload()
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.delete()
    }
    
    func updatePassword(_ newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.updatePassword(to: newPassword)
    }
    
    func updateDisplayName(_ displayName: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
    }
    
    func updateEmail(_ newEmail: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.updateEmail(to: newEmail)
        // Send verification email for new email address
        try await user.sendEmailVerification()
    }
    
    // MARK: - Token Management
    
    func getCurrentIDToken(forcingRefresh: Bool = false) async throws -> String {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        return try await user.getIDToken(forcingRefresh: forcingRefresh)
    }
    
    func refreshIDToken() async throws -> String {
        return try await getCurrentIDToken(forcingRefresh: true)
    }
    
    // MARK: - User State
    
    var currentUser: FirebaseAuth.User? {
        return auth.currentUser
    }
    
    var isUserSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    var isUserEmailVerified: Bool {
        return auth.currentUser?.isEmailVerified ?? false
    }
    
    // MARK: - Reauthentication
    
    func reauthenticate(email: String, password: String) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }
    
    func reauthenticateWithCredential(_ credential: AuthCredential) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.reauthenticate(with: credential)
    }
    
    // MARK: - Phone Authentication (Future Implementation)
    
    func verifyPhoneNumber(_ phoneNumber: String) async throws -> String {
        return try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
    }
    
    func signInWithPhoneCredential(verificationID: String, verificationCode: String) async throws -> AuthDataResult {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        return try await auth.signIn(with: credential)
    }
    
    // MARK: - Google Sign-In Integration (Future Implementation)
    
    func signInWithGoogle(credential: AuthCredential) async throws -> AuthDataResult {
        return try await auth.signIn(with: credential)
    }
    
    // MARK: - Anonymous Authentication
    
    func signInAnonymously() async throws -> AuthDataResult {
        return try await auth.signInAnonymously()
    }
    
    func linkAnonymousAccount(email: String, password: String) async throws -> AuthDataResult {
        guard let user = auth.currentUser, user.isAnonymous else {
            throw AuthenticationError.operationNotAllowed
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await user.link(with: credential)
    }
    
    // MARK: - Account Linking
    
    func linkAccount(with credential: AuthCredential) async throws -> AuthDataResult {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        return try await user.link(with: credential)
    }
    
    func unlinkProvider(_ provider: String) async throws -> FirebaseAuth.User {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        return try await user.unlink(fromProvider: provider)
    }
    
    // MARK: - Security and Validation
    
    func validateCurrentSession() async throws -> Bool {
        guard let user = auth.currentUser else {
            return false
        }
        
        do {
            // Try to get a fresh token to validate the session
            _ = try await user.getIDToken(forcingRefresh: true)
            return true
        } catch {
            return false
        }
    }
    
    func checkActionCode(_ code: String) async throws -> ActionCodeInfo {
        return try await auth.checkActionCode(code)
    }
    
    func confirmPasswordReset(code: String, newPassword: String) async throws {
        try await auth.confirmPasswordReset(withCode: code, newPassword: newPassword)
    }
    
    func applyActionCode(_ code: String) async throws {
        try await auth.applyActionCode(code)
    }
    
    // MARK: - Multi-Factor Authentication (Future Implementation)
    
    func enrollMultiFactor(assertion: MultiFactorAssertion, session: MultiFactorSession) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.multiFactor.enroll(with: assertion, displayName: nil)
    }
    
    func unenrollMultiFactor(info: MultiFactorInfo) async throws {
        guard let user = auth.currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        try await user.multiFactor.unenroll(with: info)
    }
    
    // MARK: - Error Handling Helpers
    
    func handleAuthError(_ error: Error) -> AuthenticationError {
        return AuthenticationError.fromFirebaseError(error)
    }
    
    // MARK: - Session Monitoring
    
    func addAuthStateListener(_ listener: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return auth.addStateDidChangeListener(listener)
    }
    
    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    func useEmulator(host: String, port: Int) {
        auth.useEmulator(withHost: host, port: port)
    }
    #endif
}