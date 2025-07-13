import SwiftUI

// MARK: - Sign Up View

struct SignUpView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var acceptTerms = false
    @State private var subscribeNewsletter = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName
        case lastName
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Name Fields
                nameFieldsView
                
                // Email Field
                emailFieldView
                
                // Password Fields
                passwordFieldsView
                
                // Password Strength Indicator
                passwordStrengthView
                
                // Terms and Newsletter
                agreementSectionView
                
                // Sign Up Button
                signUpButtonView
                
                // Error Display
                if let errorMessage = authManager.errorMessage {
                    errorView(errorMessage)
                }
                
                // Success Message
                if authManager.authState.isAuthenticated {
                    successView
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
        .onSubmit {
            advanceToNextField()
        }
    }
    
    // MARK: - Name Fields
    
    private var nameFieldsView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("First Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("First name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.givenName)
                    .focused($focusedField, equals: .firstName)
                    .accessibilityLabel("First name")
                    .accessibilityHint("Enter your first name")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Last name", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.familyName)
                    .focused($focusedField, equals: .lastName)
                    .accessibilityLabel("Last name")
                    .accessibilityHint("Enter your last name")
            }
        }
    }
    
    // MARK: - Email Field
    
    private var emailFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: .email)
                    .accessibilityIdentifier("emailTextField")
                    .accessibilityLabel("Email address")
                    .accessibilityHint("Enter your email address for your account")
                
                if !email.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Password Fields
    
    private var passwordFieldsView: some View {
        VStack(spacing: 16) {
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Group {
                        if showPassword {
                            TextField("Create a password", text: $password)
                        } else {
                            SecureField("Create a password", text: $password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .accessibilityIdentifier("passwordTextField")
                    .accessibilityLabel("Password")
                    .accessibilityHint("Create a secure password with at least 8 characters")
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirm your password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm your password", text: $confirmPassword)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .accessibilityIdentifier("confirmPasswordTextField")
                    .accessibilityLabel("Confirm password")
                    .accessibilityHint("Re-enter your password to confirm")
                    
                    Button(action: {
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel(showConfirmPassword ? "Hide confirm password" : "Show confirm password")
                }
                
                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Password Strength
    
    private var passwordStrengthView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !password.isEmpty {
                HStack {
                    Text("Password Strength:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(passwordStrength.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(passwordStrength.color)
                }
                
                ProgressView(value: passwordStrength.value, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: passwordStrength.color))
                    .frame(height: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(passwordRequirements, id: \.description) { requirement in
                        HStack(spacing: 6) {
                            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(requirement.isMet ? .green : .secondary)
                            
                            Text(requirement.description)
                                .font(.caption)
                                .foregroundColor(requirement.isMet ? .primary : .secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Agreement Section
    
    private var agreementSectionView: some View {
        VStack(spacing: 12) {
            Button(action: {
                acceptTerms.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: acceptTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(acceptTerms ? .blue : .secondary)
                    
                    HStack(spacing: 0) {
                        Text("I agree to the ")
                            .font(.subheadline)
                        
                        Button("Terms of Service") {
                            // Open terms of service
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        
                        Text(" and ")
                            .font(.subheadline)
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .accessibilityLabel("Accept terms and conditions")
            
            Button(action: {
                subscribeNewsletter.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: subscribeNewsletter ? "checkmark.square.fill" : "square")
                        .foregroundColor(subscribeNewsletter ? .blue : .secondary)
                    
                    Text("Subscribe to newsletter for updates and features")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .accessibilityLabel("Subscribe to newsletter")
        }
    }
    
    // MARK: - Sign Up Button
    
    private var signUpButtonView: some View {
        Button(action: {
            Task {
                await signUp()
            }
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSignUpEnabled ? Color.blue : Color.gray.opacity(0.3))
            )
            .foregroundColor(.white)
        }
        .disabled(!isSignUpEnabled || authManager.isLoading)
        .accessibilityIdentifier("signUpButton")
        .accessibilityLabel("Create account")
        .accessibilityHint("Tap to create your new account")
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
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text("Account Created Successfully!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Please check your email to verify your account.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private var isSignUpEnabled: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        isValidEmail &&
        passwordStrength.value >= 0.6 &&
        passwordsMatch &&
        acceptTerms
    }
    
    private var displayName: String {
        return "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
    
    // MARK: - Password Validation
    
    private struct PasswordRequirement {
        let description: String
        let isMet: Bool
    }
    
    private var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(description: "At least 8 characters", isMet: password.count >= 8),
            PasswordRequirement(description: "Contains uppercase letter", isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil),
            PasswordRequirement(description: "Contains lowercase letter", isMet: password.range(of: "[a-z]", options: .regularExpression) != nil),
            PasswordRequirement(description: "Contains number", isMet: password.range(of: "[0-9]", options: .regularExpression) != nil),
            PasswordRequirement(description: "Contains special character", isMet: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil)
        ]
    }
    
    private var passwordStrength: (value: Double, description: String, color: Color) {
        let metRequirements = passwordRequirements.filter { $0.isMet }.count
        let strength = Double(metRequirements) / Double(passwordRequirements.count)
        
        switch strength {
        case 0.0..<0.3:
            return (strength, "Weak", .red)
        case 0.3..<0.6:
            return (strength, "Fair", .orange)
        case 0.6..<0.8:
            return (strength, "Good", .yellow)
        case 0.8...1.0:
            return (strength, "Strong", .green)
        default:
            return (0.0, "Very Weak", .red)
        }
    }
    
    // MARK: - Actions
    
    private func signUp() async {
        // Dismiss keyboard
        focusedField = nil
        
        // Clear any previous errors
        await MainActor.run {
            authManager.clearError()
        }
        
        // Validate input
        guard isSignUpEnabled else { return }
        
        // Perform sign up
        await authManager.signUp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    private func advanceToNextField() {
        switch focusedField {
        case .firstName:
            focusedField = .lastName
        case .lastName:
            focusedField = .email
        case .email:
            focusedField = .password
        case .password:
            focusedField = .confirmPassword
        case .confirmPassword:
            focusedField = nil
        case .none:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
        .environment(AuthenticationManager())
}