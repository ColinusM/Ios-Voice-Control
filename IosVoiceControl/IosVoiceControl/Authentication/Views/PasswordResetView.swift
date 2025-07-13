import SwiftUI

// MARK: - Password Reset View

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthenticationManager.self) private var authManager
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                headerView
                
                if showSuccess {
                    successView
                } else {
                    // Email Input Form
                    emailFormView
                    
                    // Reset Button
                    resetButtonView
                    
                    // Error Display
                    if let errorMessage = errorMessage {
                        errorView(errorMessage)
                    }
                }
                
                Spacer()
                
                // Additional Help
                helpSectionView
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Forgot Your Password?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("No worries! Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Email Form
    
    private var emailFormView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Enter your email address", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isEmailFocused)
                    .accessibilityIdentifier("resetEmailTextField")
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter the email address associated with your account")
                    .onSubmit {
                        Task {
                            await resetPassword()
                        }
                    }
                
                if !email.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Reset Button
    
    private var resetButtonView: some View {
        Button(action: {
            Task {
                await resetPassword()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Send Reset Link")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isResetEnabled ? Color.blue : Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!isResetEnabled || isLoading)
        .accessibilityIdentifier("sendResetLinkButton")
        .accessibilityLabel("Send reset link")
        .accessibilityHint("Tap to send a password reset link to your email")
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Reset Link Sent!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("We've sent a password reset link to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                VStack(spacing: 8) {
                    Text("Please check your email and click the link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Don't forget to check your spam folder if you don't see the email.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Button("Resend Email") {
                    Task {
                        await resetPassword()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .disabled(isLoading)
                
                Button("Return to Sign In") {
                    dismiss()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Reset Failed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Help Section
    
    private var helpSectionView: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(spacing: 12) {
                Text("Need Additional Help?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(spacing: 8) {
                    helpButton(
                        icon: "questionmark.circle",
                        title: "FAQ & Support",
                        action: openSupport
                    )
                    
                    helpButton(
                        icon: "envelope",
                        title: "Contact Support",
                        action: contactSupport
                    )
                    
                    helpButton(
                        icon: "person.badge.plus",
                        title: "Create New Account",
                        action: createNewAccount
                    )
                }
            }
        }
    }
    
    private func helpButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var isResetEnabled: Bool {
        !email.isEmpty && isValidEmail
    }
    
    // MARK: - Actions
    
    private func resetPassword() async {
        // Dismiss keyboard
        isEmailFocused = false
        
        guard isResetEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        let success = await authManager.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        
        await MainActor.run {
            isLoading = false
            
            if success {
                showSuccess = true
            } else {
                errorMessage = authManager.errorMessage ?? "Failed to send reset email. Please try again."
            }
        }
    }
    
    private func openSupport() {
        // Open support URL or navigate to support view
        if let url = URL(string: "https://support.voicecontrol.app") {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        // Open email client or support contact
        if let url = URL(string: "mailto:support@voicecontrol.app?subject=Password Reset Help") {
            UIApplication.shared.open(url)
        }
    }
    
    private func createNewAccount() {
        // Navigate to sign up flow
        dismiss()
        // Additional navigation logic would go here
    }
}

// MARK: - Preview

#Preview {
    PasswordResetView()
        .environment(AuthenticationManager())
}