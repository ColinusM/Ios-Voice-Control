import Foundation

// MARK: - Input Validation Utilities

struct Validation {
    
    // MARK: - Email Validation
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validateEmail(_ email: String) -> ValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return .invalid("Email address is required")
        }
        
        if !isValidEmail(trimmedEmail) {
            return .invalid("Please enter a valid email address")
        }
        
        return .valid
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) -> PasswordValidationResult {
        var score = 0
        var requirements: [PasswordRequirement] = []
        
        // Length requirement
        let hasMinLength = password.count >= 8
        requirements.append(PasswordRequirement(
            description: "At least 8 characters",
            isMet: hasMinLength
        ))
        if hasMinLength { score += 1 }
        
        // Uppercase requirement
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        requirements.append(PasswordRequirement(
            description: "Contains uppercase letter",
            isMet: hasUppercase
        ))
        if hasUppercase { score += 1 }
        
        // Lowercase requirement
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        requirements.append(PasswordRequirement(
            description: "Contains lowercase letter",
            isMet: hasLowercase
        ))
        if hasLowercase { score += 1 }
        
        // Number requirement
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        requirements.append(PasswordRequirement(
            description: "Contains number",
            isMet: hasNumber
        ))
        if hasNumber { score += 1 }
        
        // Special character requirement
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        requirements.append(PasswordRequirement(
            description: "Contains special character",
            isMet: hasSpecialChar
        ))
        if hasSpecialChar { score += 1 }
        
        // No common patterns
        let hasNoCommonPatterns = !containsCommonPatterns(password)
        if hasNoCommonPatterns { score += 1 }
        
        let strength = PasswordStrength.from(score: score, totalRequirements: requirements.count)
        
        return PasswordValidationResult(
            strength: strength,
            requirements: requirements,
            isValid: score >= 3 && hasMinLength // Minimum requirements
        )
    }
    
    private static func containsCommonPatterns(_ password: String) -> Bool {
        let commonPatterns = [
            "123456",
            "password",
            "qwerty",
            "abc123",
            "admin",
            "letmein"
        ]
        
        let lowercasePassword = password.lowercased()
        return commonPatterns.contains { lowercasePassword.contains($0) }
    }
    
    static func passwordsMatch(_ password: String, _ confirmPassword: String) -> ValidationResult {
        if password != confirmPassword {
            return .invalid("Passwords do not match")
        }
        return .valid
    }
    
    // MARK: - Name Validation
    
    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid("Name is required")
        }
        
        if trimmedName.count < 2 {
            return .invalid("Name must be at least 2 characters")
        }
        
        if trimmedName.count > 50 {
            return .invalid("Name must be less than 50 characters")
        }
        
        // Check for valid characters (letters, spaces, hyphens, apostrophes)
        let nameRegex = #"^[a-zA-Z\s'\-]+$"#
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        
        if !namePredicate.evaluate(with: trimmedName) {
            return .invalid("Name can only contain letters, spaces, hyphens, and apostrophes")
        }
        
        return .valid
    }
    
    // MARK: - Phone Number Validation
    
    static func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedPhone.isEmpty {
            return .invalid("Phone number is required")
        }
        
        // Remove all non-digit characters
        let digitsOnly = trimmedPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Check for valid length (10-15 digits)
        if digitsOnly.count < 10 || digitsOnly.count > 15 {
            return .invalid("Phone number must be between 10 and 15 digits")
        }
        
        return .valid
    }
    
    // MARK: - Generic Field Validation
    
    static func validateRequired(_ value: String, fieldName: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedValue.isEmpty {
            return .invalid("\(fieldName) is required")
        }
        
        return .valid
    }
    
    static func validateLength(_ value: String, fieldName: String, min: Int? = nil, max: Int? = nil) -> ValidationResult {
        let count = value.count
        
        if let minLength = min, count < minLength {
            return .invalid("\(fieldName) must be at least \(minLength) characters")
        }
        
        if let maxLength = max, count > maxLength {
            return .invalid("\(fieldName) must be less than \(maxLength) characters")
        }
        
        return .valid
    }
    
    // MARK: - Multiple Field Validation
    
    static func validateFields(_ validations: [ValidationResult]) -> ValidationResult {
        for validation in validations {
            if case .invalid(let message) = validation {
                return .invalid(message)
            }
        }
        return .valid
    }
    
    // MARK: - Real-time Validation Helpers
    
    static func shouldShowValidation(for text: String, hasBeenEdited: Bool) -> Bool {
        return hasBeenEdited && !text.isEmpty
    }
    
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard digitsOnly.count >= 10 else { return phoneNumber }
        
        let areaCode = String(digitsOnly.prefix(3))
        let firstThree = String(digitsOnly.dropFirst(3).prefix(3))
        let lastFour = String(digitsOnly.dropFirst(6).prefix(4))
        
        return "(\(areaCode)) \(firstThree)-\(lastFour)"
    }
}

// MARK: - Validation Models

enum ValidationResult: Equatable {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

struct PasswordRequirement {
    let description: String
    let isMet: Bool
}

struct PasswordValidationResult {
    let strength: PasswordStrength
    let requirements: [PasswordRequirement]
    let isValid: Bool
    
    var strengthPercentage: Double {
        let metRequirements = requirements.filter { $0.isMet }.count
        return Double(metRequirements) / Double(requirements.count)
    }
}

enum PasswordStrength: CaseIterable {
    case veryWeak
    case weak
    case fair
    case good
    case strong
    
    static func from(score: Int, totalRequirements: Int) -> PasswordStrength {
        let percentage = Double(score) / Double(totalRequirements)
        
        switch percentage {
        case 0.0..<0.2:
            return .veryWeak
        case 0.2..<0.4:
            return .weak
        case 0.4..<0.6:
            return .fair
        case 0.6..<0.8:
            return .good
        case 0.8...1.0:
            return .strong
        default:
            return .veryWeak
        }
    }
    
    var description: String {
        switch self {
        case .veryWeak:
            return "Very Weak"
        case .weak:
            return "Weak"
        case .fair:
            return "Fair"
        case .good:
            return "Good"
        case .strong:
            return "Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .veryWeak:
            return .red
        case .weak:
            return .orange
        case .fair:
            return .yellow
        case .good:
            return .blue
        case .strong:
            return .green
        }
    }
    
    var value: Double {
        switch self {
        case .veryWeak:
            return 0.1
        case .weak:
            return 0.3
        case .fair:
            return 0.5
        case .good:
            return 0.7
        case .strong:
            return 1.0
        }
    }
}

// MARK: - Validation Extensions

extension String {
    var isValidEmail: Bool {
        return Validation.isValidEmail(self)
    }
    
    var formattedPhoneNumber: String {
        return Validation.formatPhoneNumber(self)
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension Color {
    init(_ passwordStrength: PasswordStrength) {
        self = passwordStrength.color
    }
}