import Foundation
import FirebaseAuth

// MARK: - Social Authentication Result Models

/// Unified result from social authentication providers
struct SocialAuthResult {
    let provider: SocialAuthProvider
    let firebaseUser: FirebaseAuth.User
    let profile: SocialUserProfile
    let credentials: SocialCredentials
    let isNewUser: Bool
    
    init(provider: SocialAuthProvider, firebaseUser: FirebaseAuth.User, profile: SocialUserProfile, credentials: SocialCredentials, isNewUser: Bool = false) {
        self.provider = provider
        self.firebaseUser = firebaseUser
        self.profile = profile
        self.credentials = credentials
        self.isNewUser = isNewUser
    }
}

/// Social authentication provider types
enum SocialAuthProvider: String, CaseIterable {
    case google = "google.com"
    case apple = "apple.com"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        }
    }
    
    var iconName: String {
        switch self {
        case .google:
            return "google_logo"
        case .apple:
            return "apple.logo"
        }
    }
}

/// Unified social user profile information
struct SocialUserProfile {
    let userId: String?
    let email: String?
    let displayName: String?
    let firstName: String?
    let lastName: String?
    let imageURL: URL?
    let isEmailVerified: Bool
    let provider: SocialAuthProvider
    
    init(
        userId: String?,
        email: String?,
        displayName: String?,
        firstName: String? = nil,
        lastName: String? = nil,
        imageURL: URL? = nil,
        isEmailVerified: Bool = false,
        provider: SocialAuthProvider
    ) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.imageURL = imageURL
        self.isEmailVerified = isEmailVerified
        self.provider = provider
    }
}

/// Social authentication credentials
struct SocialCredentials {
    let idToken: String?
    let accessToken: String?
    let authorizationCode: String?
    let provider: SocialAuthProvider
    let expirationDate: Date?
    
    init(
        idToken: String?,
        accessToken: String?,
        authorizationCode: String? = nil,
        provider: SocialAuthProvider,
        expirationDate: Date? = nil
    ) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.authorizationCode = authorizationCode
        self.provider = provider
        self.expirationDate = expirationDate
    }
}

// MARK: - Firebase Integration Extensions

extension SocialAuthResult {
    /// Creates a Firebase-compatible User model from social auth result
    func toUser() -> User {
        return User(
            uid: firebaseUser.uid,
            email: profile.email,
            displayName: profile.displayName,
            isEmailVerified: profile.isEmailVerified,
            creationDate: Date(),
            lastSignInDate: Date(),
            phoneNumber: firebaseUser.phoneNumber,
            photoURL: profile.imageURL
        )
    }
}

extension SocialUserProfile {
    /// Creates profile from Google Sign-In user
    static func fromGoogle(userId: String?, email: String?, displayName: String?, imageURL: URL?) -> SocialUserProfile {
        let nameParts = displayName?.split(separator: " ").map(String.init)
        let firstName = nameParts?.first
        let lastName = nameParts?.count ?? 0 > 1 ? nameParts?[1...].joined(separator: " ") : nil
        
        return SocialUserProfile(
            userId: userId,
            email: email,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            imageURL: imageURL,
            isEmailVerified: true, // Google accounts are typically verified
            provider: .google
        )
    }
    
    /// Creates profile from Apple Sign-In user
    static func fromApple(userId: String, email: String?, fullName: PersonNameComponents?) -> SocialUserProfile {
        let displayName = fullName?.formatted() ?? "Apple User"
        
        return SocialUserProfile(
            userId: userId,
            email: email,
            displayName: displayName,
            firstName: fullName?.givenName,
            lastName: fullName?.familyName,
            imageURL: nil, // Apple doesn't provide profile images
            isEmailVerified: email?.contains("privaterelay.appleid.com") == false,
            provider: .apple
        )
    }
}

// MARK: - Validation and Security

extension SocialCredentials {
    /// Validates that required credentials are present based on provider
    var isValid: Bool {
        switch provider {
        case .google:
            return idToken != nil && accessToken != nil
        case .apple:
            return idToken != nil
        }
    }
    
    /// Checks if credentials are expired
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() >= expirationDate
    }
}

extension SocialUserProfile {
    /// Validates that required profile information is present
    var isValid: Bool {
        return userId != nil && email != nil && !email!.isEmpty
    }
    
    /// Checks if this is an Apple private relay email
    var isApplePrivateEmail: Bool {
        return email?.contains("privaterelay.appleid.com") == true
    }
}