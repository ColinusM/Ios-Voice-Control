import Foundation
import FirebaseAuth

// MARK: - Secure User Model

struct User: Codable, Equatable {
    let uid: String
    let email: String?
    let displayName: String?
    let isEmailVerified: Bool
    let creationDate: Date
    let lastSignInDate: Date
    let phoneNumber: String?
    let photoURL: URL?
    
    // MARK: - Computed Properties
    
    var initials: String {
        guard let displayName = displayName, !displayName.isEmpty else {
            return email?.prefix(2).uppercased() ?? "U"
        }
        
        let components = displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    var hasValidEmail: Bool {
        guard let email = email else { return false }
        return !email.isEmpty && email.contains("@")
    }
    
    // MARK: - Firebase User Conversion
    
    static func from(firebaseUser: FirebaseAuth.User) -> User {
        return User(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            isEmailVerified: firebaseUser.isEmailVerified,
            creationDate: firebaseUser.metadata.creationDate ?? Date(),
            lastSignInDate: firebaseUser.metadata.lastSignInDate ?? Date(),
            phoneNumber: firebaseUser.phoneNumber,
            photoURL: firebaseUser.photoURL
        )
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case uid
        case email
        case displayName
        case isEmailVerified
        case creationDate
        case lastSignInDate
        case phoneNumber
        case photoURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        isEmailVerified = try container.decode(Bool.self, forKey: .isEmailVerified)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        lastSignInDate = try container.decode(Date.self, forKey: .lastSignInDate)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        
        if let photoURLString = try container.decodeIfPresent(String.self, forKey: .photoURL) {
            photoURL = URL(string: photoURLString)
        } else {
            photoURL = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uid, forKey: .uid)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(isEmailVerified, forKey: .isEmailVerified)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(lastSignInDate, forKey: .lastSignInDate)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(photoURL?.absoluteString, forKey: .photoURL)
    }
}

// MARK: - User Extensions

extension User {
    var isProfileComplete: Bool {
        return hasValidEmail && displayName != nil && !displayName!.isEmpty
    }
    
    var accountAge: TimeInterval {
        return Date().timeIntervalSince(creationDate)
    }
    
    var timeSinceLastSignIn: TimeInterval {
        return Date().timeIntervalSince(lastSignInDate)
    }
}