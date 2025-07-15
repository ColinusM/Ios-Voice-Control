import SwiftUI

// MARK: - Sign In View

struct SignInView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var biometricManager = BiometricAuthManager()
    
    @Binding var showPasswordReset: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberMe = false
    @State private var showBiometricPrompt = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Email Field
                emailFieldView
                
                // Password Field
                passwordFieldView
                
                // Remember Me & Forgot Password
                optionsRowView
                
                // Sign In Button
                signInButtonView
                
                // Biometric Authentication
                if biometricManager.isAvailable && biometricManager.isEnabled {
                    biometricAuthView
                }
                
                // Social Sign-In Section
                if Constants.FeatureFlags.googleSignInEnabled {
                    socialSignInSection
                }
                
                // Error Display
                if let errorMessage = authManager.errorMessage {
                    errorView(errorMessage)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .task {
            await loadBiometricCapabilities()
        }
        .onAppear {
            loadSavedCredentials()
            checkBiometricPrompt()
        }
    }
    
    // MARK: - Email Field
    
    private var emailFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField("Enter your email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .email)
                .accessibilityIdentifier("emailTextField")
                .accessibilityLabel("Email address")
                .accessibilityHint("Enter your email address to sign in")
        }
    }
    
    // MARK: - Password Field
    
    private var passwordFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            HStack {
                Group {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                    } else {
                        SecureField("Enter your password", text: $password)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .accessibilityIdentifier("passwordTextField")
                .accessibilityLabel("Password")
                .accessibilityHint("Enter your password to sign in")
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(showPassword ? "Hide password" : "Show password")
            }
        }
    }
    
    // MARK: - Options Row
    
    private var optionsRowView: some View {
        HStack {
            Button(action: {
                rememberMe.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                        .foregroundColor(rememberMe ? .blue : .secondary)
                    
                    Text("Remember me")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button("Forgot Password?") {
                showPasswordReset = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Sign In Button
    
    private var signInButtonView: some View {
        Button(action: {
            Task {
                await signIn()
            }
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSignInEnabled ? Color.blue : Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!isSignInEnabled || authManager.isLoading)
        .accessibilityIdentifier("signInButton")
        .accessibilityLabel("Sign in")
        .accessibilityHint("Tap to sign in with your email and password")
    }
    
    // MARK: - Biometric Authentication
    
    private var biometricAuthView: some View {
        VStack(spacing: 16) {
            Text("Or")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await authenticateWithBiometrics()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: biometricIconName)
                        .font(.title2)
                    
                    Text("Sign in with \(biometricManager.getBiometricTypeDisplayName())")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .foregroundColor(.blue)
            }
            .disabled(biometricManager.isAuthenticating)
            .accessibilityIdentifier("biometricAuthButton")
            .accessibilityLabel("Biometric authentication")
            .accessibilityHint("Use Face ID or Touch ID to sign in")
        }
    }
    
    // MARK: - Social Sign-In
    
    private var socialSignInSection: some View {
        VStack(spacing: 16) {
            Text("Or continue with")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Google Sign-In Button  
            if Constants.FeatureFlags.googleSignInEnabled {
                GoogleSignInButton.standard(
                    action: {
                        Task {
                            await signInWithGoogle()
                        }
                    },
                    isLoading: authManager.isLoading
                )
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isSignInEnabled: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "person.crop.circle.badge.checkmark"
        }
    }
    
    // MARK: - Actions
    
    private func signIn() async {
        // Dismiss keyboard
        focusedField = nil
        
        // Clear any previous errors
        await MainActor.run {
            authManager.clearError()
        }
        
        // Validate input
        guard isSignInEnabled else { return }
        
        // Perform sign in
        await authManager.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), 
                               password: password)
        
        // Save credentials if remember me is enabled and sign in was successful
        if rememberMe && authManager.authState.isAuthenticated {
            saveCredentials()
        }
    }
    
    private func authenticateWithBiometrics() async {
        let success = await biometricManager.authenticateWithBiometrics()
        
        if success {
            // Complete biometric authentication in auth manager
            await MainActor.run {
                authManager.completeBiometricAuth()
            }
        }
    }
    
    private func signInWithGoogle() async {
        // Dismiss keyboard
        focusedField = nil
        
        // Clear any previous errors
        await MainActor.run {
            authManager.clearError()
        }
        
        // Perform Google Sign-In
        await authManager.signInWithGoogle()
    }
    
    
    // MARK: - Credential Management
    
    private func loadSavedCredentials() {
        if let savedEmail = UserDefaults.standard.string(forKey: "saved_email") {
            email = savedEmail
            rememberMe = true
        }
    }
    
    private func saveCredentials() {
        if rememberMe {
            UserDefaults.standard.set(email, forKey: "saved_email")
        } else {
            UserDefaults.standard.removeObject(forKey: "saved_email")
        }
    }
    
    // MARK: - Biometric Setup
    
    private func loadBiometricCapabilities() async {
        await biometricManager.loadBiometricCapabilities()
    }
    
    private func checkBiometricPrompt() {
        if biometricManager.promptForBiometricSetup() {
            showBiometricPrompt = true
        }
    }
}

// MARK: - Preview

#Preview {
    SignInView(showPasswordReset: .constant(false))
        .environment(AuthenticationManager())
}