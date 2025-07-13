import SwiftUI
import LocalAuthentication

// MARK: - Account Management View

struct AccountManagementView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var biometricManager = BiometricAuthManager()
    @State private var networkMonitor = NetworkMonitor.shared
    
    // Form state
    @State private var showingPasswordChange = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEmailVerification = false
    @State private var isEditing = false
    
    // Profile editing
    @State private var displayName = ""
    @State private var email = ""
    
    // Settings
    @State private var biometricEnabled = false
    @State private var notificationsEnabled = false
    
    // Loading states
    @State private var isUpdatingProfile = false
    @State private var isSendingVerification = false
    @State private var isDeletingAccount = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection
                
                // Security Section
                securitySection
                
                // Preferences Section
                preferencesSection
                
                // Account Actions Section
                accountActionsSection
                
                // App Information Section
                appInfoSection
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            Task {
                                await saveProfile()
                            }
                        } else {
                            startEditing()
                        }
                    }
                    .disabled(isUpdatingProfile)
                }
            }
            .sheet(isPresented: $showingPasswordChange) {
                PasswordChangeView()
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                deleteAccountAlert
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .task {
                await loadUserData()
                await loadSettings()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(userInitials)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)
                    } else {
                        Text(displayName.isEmpty ? "Add Your Name" : displayName)
                            .font(.headline)
                            .foregroundColor(displayName.isEmpty ? .secondary : .primary)
                    }
                    
                    HStack {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !isEmailVerified {
                            Button("Verify") {
                                Task {
                                    await sendEmailVerification()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .disabled(isSendingVerification)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                if isUpdatingProfile {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Profile")
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        Section {
            // Biometric Authentication
            HStack {
                Image(systemName: biometricIconName)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(biometricManager.getBiometricTypeDisplayName())
                        .font(.body)
                    
                    if !biometricManager.isAvailable {
                        Text("Not available on this device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $biometricEnabled)
                    .disabled(!biometricManager.isAvailable)
                    .onChange(of: biometricEnabled) { _, newValue in
                        biometricManager.setBiometricEnabled(newValue)
                    }
            }
            
            // Password Change
            Button(action: {
                showingPasswordChange = true
            }) {
                HStack {
                    Image(systemName: "key.horizontal")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Change Password")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Security Status
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Account Security")
                        .font(.body)
                    
                    Text(securityStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        } header: {
            Text("Security")
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            // Notifications (future feature)
            HStack {
                Image(systemName: "bell")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Push Notifications")
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .disabled(true) // Future feature
            }
            
            // Network Status
            HStack {
                Image(systemName: networkMonitor.connectionType.icon)
                    .foregroundColor(networkMonitor.isConnected ? .green : .red)
                    .frame(width: 24)
                
                Text("Network Status")
                
                Spacer()
                
                Text(networkMonitor.statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Preferences")
        }
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        Section {
            // Sign Out
            Button(action: {
                Task {
                    await signOut()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Sign Out")
                        .foregroundColor(.primary)
                }
            }
            
            // Delete Account
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
            }
            .disabled(isDeletingAccount)
        } header: {
            Text("Account Actions")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            // App Version
            HStack {
                Text("Version")
                Spacer()
                Text(Constants.App.version)
                    .foregroundColor(.secondary)
            }
            
            // Build Number
            HStack {
                Text("Build")
                Spacer()
                Text(Constants.App.build)
                    .foregroundColor(.secondary)
            }
            
            // Privacy Policy
            Button("Privacy Policy") {
                openURL(Constants.Network.URLs.privacy)
            }
            .foregroundColor(.blue)
            
            // Terms of Service
            Button("Terms of Service") {
                openURL(Constants.Network.URLs.terms)
            }
            .foregroundColor(.blue)
            
            // Support
            Button("Contact Support") {
                openURL(Constants.Network.URLs.contactSupport)
            }
            .foregroundColor(.blue)
        } header: {
            Text("App Information")
        }
    }
    
    // MARK: - Delete Account Alert
    
    @ViewBuilder
    private var deleteAccountAlert: some View {
        Button("Cancel", role: .cancel) { }
        
        Button("Delete", role: .destructive) {
            Task {
                await deleteAccount()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var userInitials: String {
        if let user = authManager.currentUser {
            return user.initials
        }
        return "U"
    }
    
    private var isEmailVerified: Bool {
        return authManager.currentUser?.isEmailVerified ?? false
    }
    
    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var securityStatusText: String {
        let hasPassword = true // Always true for email/password auth
        let hasBiometric = biometricEnabled && biometricManager.isAvailable
        let isVerified = isEmailVerified
        
        var components: [String] = []
        
        if hasPassword { components.append("Password") }
        if hasBiometric { components.append(biometricManager.getBiometricTypeDisplayName()) }
        if isVerified { components.append("Verified Email") }
        
        return components.isEmpty ? "Basic Security" : components.joined(separator: " • ")
    }
    
    // MARK: - Actions
    
    private func loadUserData() async {
        guard let user = authManager.currentUser else { return }
        
        await MainActor.run {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
        }
    }
    
    private func loadSettings() async {
        await biometricManager.loadBiometricCapabilities()
        
        await MainActor.run {
            biometricEnabled = biometricManager.isEnabled
            // Load other settings here
        }
    }
    
    private func startEditing() {
        isEditing = true
    }
    
    private func saveProfile() async {
        isUpdatingProfile = true
        
        // Here you would update the user profile
        // For now, we'll just simulate the update
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            isUpdatingProfile = false
            isEditing = false
        }
    }
    
    private func sendEmailVerification() async {
        isSendingVerification = true
        
        let success = await authManager.sendEmailVerification()
        
        await MainActor.run {
            isSendingVerification = false
            if success {
                showingEmailVerification = true
            }
        }
    }
    
    private func signOut() async {
        await authManager.signOut()
    }
    
    private func deleteAccount() async {
        isDeletingAccount = true
        
        let success = await authManager.deleteAccount()
        
        await MainActor.run {
            isDeletingAccount = false
            // Account deletion will be handled by auth state listener
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Password Change View

struct PasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureTextField.password(
                        title: "Current Password",
                        text: $currentPassword
                    )
                    
                    SecureTextField.newPassword(
                        title: "New Password",
                        text: $newPassword
                    )
                    
                    SecureTextField.confirmPassword(
                        text: $confirmPassword,
                        validationResult: passwordValidation
                    )
                } header: {
                    Text("Change Password")
                } footer: {
                    Text("Your new password must be at least 8 characters long and include uppercase and lowercase letters, numbers, and special characters.")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    LoadingButton.primary(
                        "Save",
                        isLoading: isLoading,
                        isEnabled: canChangePassword
                    ) {
                        Task {
                            await changePassword()
                        }
                    }
                }
            }
        }
    }
    
    private var passwordValidation: ValidationResult {
        return Validation.passwordsMatch(newPassword, confirmPassword)
    }
    
    private var canChangePassword: Bool {
        let newPasswordValid = Validation.validatePassword(newPassword)
        return !currentPassword.isEmpty &&
               newPasswordValid.isValid &&
               passwordValidation.isValid
    }
    
    private func changePassword() async {
        isLoading = true
        errorMessage = nil
        
        // Here you would implement password change logic
        // This would typically involve reauthentication with current password
        // then updating to the new password
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AccountManagementView()
        .environment(AuthenticationManager())
}