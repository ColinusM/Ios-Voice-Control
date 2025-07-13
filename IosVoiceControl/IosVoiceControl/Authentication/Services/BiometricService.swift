import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Service

class BiometricService {
    
    // MARK: - Biometric Error Types
    
    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case lockout
        case temporaryLockout
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case touchIDNotAvailable
        case faceIDNotAvailable
        case invalidContext
        case authenticationFailed
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device."
            case .notEnrolled:
                return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
            case .lockout:
                return "Biometric authentication is locked out. Please use your passcode."
            case .temporaryLockout:
                return "Too many failed attempts. Please try again later."
            case .userCancel:
                return "Authentication was cancelled by the user."
            case .userFallback:
                return "User chose to use fallback authentication method."
            case .systemCancel:
                return "Authentication was cancelled by the system."
            case .passcodeNotSet:
                return "Device passcode is not set. Please set up a passcode in Settings."
            case .touchIDNotAvailable:
                return "Touch ID is not available on this device."
            case .faceIDNotAvailable:
                return "Face ID is not available on this device."
            case .invalidContext:
                return "Invalid authentication context."
            case .authenticationFailed:
                return "Authentication failed. Please try again."
            case .unknown(let error):
                return "Authentication error: \(error.localizedDescription)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .notAvailable, .touchIDNotAvailable, .faceIDNotAvailable:
                return "Use password authentication instead."
            case .notEnrolled:
                return "Go to Settings > Face ID & Passcode or Touch ID & Passcode to set up biometric authentication."
            case .lockout:
                return "Enter your device passcode to unlock biometric authentication."
            case .temporaryLockout:
                return "Wait a moment and try again, or use your passcode."
            case .userCancel, .userFallback:
                return "Try biometric authentication again or use password."
            case .systemCancel:
                return "Return to the app and try again."
            case .passcodeNotSet:
                return "Set up a device passcode in Settings first."
            case .invalidContext, .authenticationFailed:
                return "Try authenticating again."
            case .unknown:
                return "Try again or contact support if the problem persists."
            }
        }
    }
    
    // MARK: - Biometric Type Detection
    
    func getBiometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    func getBiometricTypeString() -> String {
        switch getBiometricType() {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Availability Checks
    
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func isDevicePasscodeSet() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    func getBiometricAvailabilityStatus() -> (available: Bool, error: BiometricError?) {
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            return (true, nil)
        }
        
        guard let laError = error else {
            return (false, .unknown(NSError(domain: "Unknown", code: -1)))
        }
        
        let biometricError = mapLAError(laError)
        return (false, biometricError)
    }
    
    // MARK: - Authentication Methods
    
    func authenticateWithBiometrics(reason: String = "Authenticate to access your account") async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // PATTERN: Check availability before attempting authentication
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error {
                throw mapLAError(laError)
            } else {
                throw BiometricError.notAvailable
            }
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapLAError(error)
        }
    }
    
    func authenticateWithDevicePasscode(reason: String = "Authenticate to access your account") async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let laError = error {
                throw mapLAError(laError)
            } else {
                throw BiometricError.passcodeNotSet
            }
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapLAError(error)
        }
    }
    
    // MARK: - Enhanced Authentication with Fallback
    
    func authenticateWithBiometricsAndFallback(
        reason: String = "Authenticate to access your account",
        fallbackTitle: String = "Use Passcode"
    ) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = fallbackTitle
        
        var error: NSError?
        
        // First try biometrics, then fall back to device passcode
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let laError = error {
                throw mapLAError(laError)
            } else {
                throw BiometricError.notAvailable
            }
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapLAError(error)
        }
    }
    
    // MARK: - Secure Enclave Authentication
    
    func authenticateWithSecureEnclave(reason: String = "Authenticate for secure operation") async throws -> Bool {
        let context = LAContext()
        
        // Configure for secure enclave usage
        context.touchIDAuthenticationAllowableReuseDuration = 0 // Require fresh authentication
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error {
                throw mapLAError(laError)
            } else {
                throw BiometricError.notAvailable
            }
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapLAError(error)
        }
    }
    
    // MARK: - LAError Mapping
    
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown(error)
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .appCancel:
            return .systemCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .systemCancel
        default:
            return .unknown(error)
        }
    }
    
    // MARK: - Utility Methods
    
    func getBiometricCapabilities() -> BiometricCapabilities {
        let biometricType = getBiometricType()
        let (isAvailable, error) = getBiometricAvailabilityStatus()
        let isPasscodeSet = isDevicePasscodeSet()
        
        return BiometricCapabilities(
            biometricType: biometricType,
            isAvailable: isAvailable,
            isPasscodeSet: isPasscodeSet,
            error: error
        )
    }
    
    func canUseBiometricAuthentication() -> Bool {
        let capabilities = getBiometricCapabilities()
        return capabilities.isAvailable && capabilities.isPasscodeSet
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    func simulateBiometricSuccess() async throws -> Bool {
        // For testing purposes
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        return true
    }
    
    func simulateBiometricFailure() async throws -> Bool {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        throw BiometricError.authenticationFailed
    }
    #endif
}

// MARK: - Biometric Capabilities Model

struct BiometricCapabilities {
    let biometricType: LABiometryType
    let isAvailable: Bool
    let isPasscodeSet: Bool
    let error: BiometricService.BiometricError?
    
    var biometricTypeString: String {
        switch biometricType {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        @unknown default:
            return "Unknown"
        }
    }
    
    var canAuthenticate: Bool {
        return isAvailable && isPasscodeSet && error == nil
    }
    
    var statusDescription: String {
        if canAuthenticate {
            return "\(biometricTypeString) is available and ready to use."
        } else if let error = error {
            return error.localizedDescription
        } else if !isPasscodeSet {
            return "Device passcode is not set."
        } else {
            return "Biometric authentication is not available."
        }
    }
}