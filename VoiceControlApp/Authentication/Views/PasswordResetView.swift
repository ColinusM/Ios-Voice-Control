import SwiftUI

// MARK: - Password Reset View

struct PasswordResetView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Email Input
                    emailInputView
                    
                    // Reset Button
                    resetButtonView
                    
                    // Instructions
                    instructionsView
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Check Your Email", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent a password reset link to \(email). Please check your inbox and follow the instructions.")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            // Title
            Text("Reset Your Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Subtitle
            Text("Enter your email address and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Email Input View
    
    private var emailInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isEmailFocused)
                    .onSubmit {
                        handlePasswordReset()
                    }
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter the email address associated with your account")
                
                if !email.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Reset Button View
    
    private var resetButtonView: some View {
        Button(action: handlePasswordReset) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isLoading ? "Sending..." : "Send Reset Link")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSendReset ? Color.blue : Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!canSendReset || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .accessibilityLabel("Send password reset link")
        .accessibilityHint("Tap to send a password reset link to your email")
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("What happens next?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Instructions
            VStack(spacing: 12) {
                instructionStep(
                    number: 1,
                    title: "Check your email",
                    description: "We'll send a secure link to your email address"
                )
                
                instructionStep(
                    number: 2,
                    title: "Click the link",
                    description: "Follow the link in the email to reset your password"
                )
                
                instructionStep(
                    number: 3,
                    title: "Create new password",
                    description: "Choose a strong, unique password for your account"
                )
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Instruction Step View
    
    private func instructionStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
            
            // Step content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var canSendReset: Bool {
        !email.isEmpty && isValidEmail && !isLoading
    }
    
    // MARK: - Actions
    
    private func handlePasswordReset() {
        guard canSendReset else { return }
        
        // Clear focus
        isEmailFocused = false
        
        // Clear previous errors
        errorMessage = ""
        
        // Validate email
        guard isValidEmail else {
            showError("Please enter a valid email address")
            return
        }
        
        // Start loading
        isLoading = true
        
        // Perform password reset
        Task {
            let success = await authManager.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    showingSuccessAlert = true
                } else {
                    showError(authManager.errorMessage ?? "Failed to send reset email. Please try again.")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Preview

#Preview {
    PasswordResetView()
        .environmentObject(AuthenticationManager())
}