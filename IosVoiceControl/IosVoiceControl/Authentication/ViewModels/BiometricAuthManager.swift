import Foundation
import SwiftUI
import LocalAuthentication

// MARK: - Biometric Authentication Manager with @Observable Pattern

@MainActor
@Observable
class BiometricAuthManager {
    
    // MARK: - Published Properties
    
    var biometricType: LABiometryType = .none
    var isAvailable = false
    var isEnabled = false
    var isAuthenticating = false
    var lastError: BiometricService.BiometricError?
    var capabilities: BiometricCapabilities?
    
    // MARK: - Private Properties
    
    private let biometricService = BiometricService()
    private let keychainService = KeychainService()
    
    // MARK: - User Defaults Keys
    
    private enum UserDefaultsKeys {
        static let biometricAuthEnabled = "biometric_auth_enabled"
        static let biometricPromptCount = "biometric_prompt_count"
        static let lastBiometricUse = "last_biometric_use"
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            await loadBiometricCapabilities()
            await loadUserPreferences()
        }
    }
    
    // MARK: - Capability Management
    
    func loadBiometricCapabilities() async {
        capabilities = biometricService.getBiometricCapabilities()
        biometricType = capabilities?.biometricType ?? .none
        isAvailable = capabilities?.canAuthenticate ?? false
        lastError = capabilities?.error
    }
    
    func refreshCapabilities() async {
        await loadBiometricCapabilities()
    }
    
    // MARK: - User Preferences
    
    private func loadUserPreferences() async {
        isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricAuthEnabled)
    }
    
    func setBiometricEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.biometricAuthEnabled)
        
        if enabled {
            recordBiometricPrompt()
        }
    }
    
    private func recordBiometricPrompt() {
        let currentCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.biometricPromptCount)
        UserDefaults.standard.set(currentCount + 1, forKey: UserDefaultsKeys.biometricPromptCount)
    }
    
    private func recordBiometricUse() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.lastBiometricUse)
    }
    
    // MARK: - Authentication Methods
    
    func authenticateWithBiometrics() async -> Bool {
        guard isAvailable && isEnabled else {
            lastError = .notAvailable
            return false
        }
        
        isAuthenticating = true
        lastError = nil
        
        do {
            let reason = getBiometricReason()
            let success = try await biometricService.authenticateWithBiometrics(reason: reason)
            
            if success {
                recordBiometricUse()
            }
            
            isAuthenticating = false
            return success
        } catch {
            isAuthenticating = false
            
            if let biometricError = error as? BiometricService.BiometricError {
                lastError = biometricError
            } else {
                lastError = .unknown(error)
            }
            
            return false
        }
    }
    
    func authenticateWithFallback() async -> Bool {
        guard isAvailable else {
            lastError = .notAvailable
            return false
        }
        
        isAuthenticating = true
        lastError = nil
        
        do {
            let reason = getBiometricReason()
            let fallbackTitle = "Use Passcode"
            
            let success = try await biometricService.authenticateWithBiometricsAndFallback(
                reason: reason,
                fallbackTitle: fallbackTitle
            )
            
            if success {
                recordBiometricUse()
            }
            
            isAuthenticating = false
            return success
        } catch {
            isAuthenticating = false
            
            if let biometricError = error as? BiometricService.BiometricError {
                lastError = biometricError
            } else {
                lastError = .unknown(error)
            }
            
            return false
        }
    }
    
    func authenticateForSecureOperation() async -> Bool {
        guard isAvailable && isEnabled else {
            lastError = .notAvailable
            return false
        }
        
        isAuthenticating = true
        lastError = nil
        
        do {
            let reason = "Authenticate for secure operation"
            let success = try await biometricService.authenticateWithSecureEnclave(reason: reason)
            
            if success {
                recordBiometricUse()
            }
            
            isAuthenticating = false
            return success
        } catch {
            isAuthenticating = false
            
            if let biometricError = error as? BiometricService.BiometricError {
                lastError = biometricError
            } else {
                lastError = .unknown(error)
            }
            
            return false
        }
    }
    
    // MARK: - Biometric Token Management
    
    func saveBiometricToken(_ token: String) async -> Bool {
        do {
            try KeychainService.saveBiometricToken(token)
            return true
        } catch {
            lastError = .unknown(error)
            return false
        }
    }
    
    func getBiometricToken() async -> String? {
        do {
            return try KeychainService.getBiometricToken()
        } catch {
            if !(error is KeychainService.KeychainError) {
                lastError = .unknown(error)
            }
            return nil
        }
    }
    
    func authenticateAndRetrieveToken() async -> String? {
        let authSuccess = await authenticateWithBiometrics()
        
        guard authSuccess else {
            return nil
        }
        
        return await getBiometricToken()
    }
    
    // MARK: - Setup and Enrollment
    
    func promptForBiometricSetup() -> Bool {
        // Check if we should prompt for biometric setup
        let capabilities = biometricService.getBiometricCapabilities()
        
        // Don't prompt if not available or already enabled
        guard capabilities.canAuthenticate && !isEnabled else {
            return false
        }
        
        // Limit prompts to avoid being annoying
        let promptCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.biometricPromptCount)
        let maxPrompts = 3
        
        guard promptCount < maxPrompts else {
            return false
        }
        
        return true
    }
    
    func openBiometricSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getBiometricReason() -> String {
        switch biometricType {
        case .faceID:
            return "Use Face ID to securely access your account"
        case .touchID:
            return "Use Touch ID to securely access your account"
        default:
            return "Use biometric authentication to securely access your account"
        }
    }
    
    func getBiometricTypeDisplayName() -> String {
        return capabilities?.biometricTypeString ?? "Biometric Authentication"
    }
    
    func getSetupInstructions() -> String {
        switch biometricType {
        case .faceID:
            return "Set up Face ID in Settings > Face ID & Passcode to use biometric authentication."
        case .touchID:
            return "Set up Touch ID in Settings > Touch ID & Passcode to use biometric authentication."
        default:
            return "Set up biometric authentication in Settings to use this feature."
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        lastError = nil
    }
    
    func getErrorMessage() -> String? {
        return lastError?.localizedDescription
    }
    
    func getRecoverySuggestion() -> String? {
        return lastError?.recoverySuggestion
    }
    
    func shouldShowRecoveryAction() -> Bool {
        guard let error = lastError else { return false }
        
        switch error {
        case .notEnrolled, .notAvailable, .passcodeNotSet:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Analytics and Monitoring
    
    func getBiometricUsageStats() -> BiometricUsageStats {
        let promptCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.biometricPromptCount)
        let lastUse = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastBiometricUse) as? Date
        
        return BiometricUsageStats(
            totalPrompts: promptCount,
            isEnabled: isEnabled,
            lastUse: lastUse,
            biometricType: biometricType
        )
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    func simulateSuccess() async -> Bool {
        isAuthenticating = true
        
        do {
            let success = try await biometricService.simulateBiometricSuccess()
            isAuthenticating = false
            return success
        } catch {
            isAuthenticating = false
            lastError = .unknown(error)
            return false
        }
    }
    
    func simulateFailure() async -> Bool {
        isAuthenticating = true
        
        do {
            let success = try await biometricService.simulateBiometricFailure()
            isAuthenticating = false
            return success
        } catch {
            isAuthenticating = false
            lastError = .authenticationFailed
            return false
        }
    }
    
    func resetForTesting() {
        isEnabled = false
        lastError = nil
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricAuthEnabled)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.biometricPromptCount)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastBiometricUse)
    }
    #endif
}

// MARK: - Biometric Usage Statistics

struct BiometricUsageStats {
    let totalPrompts: Int
    let isEnabled: Bool
    let lastUse: Date?
    let biometricType: LABiometryType
    
    var daysSinceLastUse: Int? {
        guard let lastUse = lastUse else { return nil }
        return Calendar.current.dateComponents([.day], from: lastUse, to: Date()).day
    }
    
    var usageFrequency: String {
        guard let days = daysSinceLastUse else { return "Never used" }
        
        switch days {
        case 0:
            return "Used today"
        case 1:
            return "Used yesterday"
        case 2...7:
            return "Used this week"
        case 8...30:
            return "Used this month"
        default:
            return "Not used recently"
        }
    }
}