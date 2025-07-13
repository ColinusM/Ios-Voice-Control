import SwiftUI

// MARK: - Secure Text Field Component

struct SecureTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    // Configuration options
    var showPasswordToggle: Bool = true
    var showStrengthIndicator: Bool = false
    var validationResult: ValidationResult? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = .password
    var autocapitalization: TextInputAutocapitalization = .never
    var disableAutocorrection: Bool = true
    
    // Accessibility
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    var accessibilityIdentifier: String? = nil
    
    // State
    @State private var isSecure = true
    @State private var isFocused = false
    @FocusState private var fieldIsFocused: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        showPasswordToggle: Bool = true,
        showStrengthIndicator: Bool = false,
        validationResult: ValidationResult? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = .password,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.showPasswordToggle = showPasswordToggle
        self.showStrengthIndicator = showStrengthIndicator
        self.validationResult = validationResult
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Text Field Container
            textFieldContainer
            
            // Validation Message
            if let validationResult = validationResult,
               case .invalid(let message) = validationResult {
                validationErrorView(message)
            }
            
            // Password Strength Indicator
            if showStrengthIndicator && !text.isEmpty {
                passwordStrengthView
            }
        }
    }
    
    // MARK: - Text Field Container
    
    private var textFieldContainer: some View {
        HStack {
            textFieldView
            
            if showPasswordToggle {
                passwordToggleButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: validationResult)
    }
    
    // MARK: - Text Field View
    
    @ViewBuilder
    private var textFieldView: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .disableAutocorrection(disableAutocorrection)
                    .focused($fieldIsFocused)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .disableAutocorrection(disableAutocorrection)
                    .focused($fieldIsFocused)
            }
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(accessibilityHint ?? "Enter your \(title.lowercased())")
        .accessibilityIdentifier(accessibilityIdentifier)
        .onChange(of: fieldIsFocused) { _, focused in
            isFocused = focused
        }
    }
    
    // MARK: - Password Toggle Button
    
    private var passwordToggleButton: some View {
        Button(action: {
            isSecure.toggle()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Image(systemName: isSecure ? "eye" : "eye.slash")
                .foregroundColor(.secondary)
                .font(.body)
        }
        .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        .accessibilityHint(isSecure ? "Tap to reveal password" : "Tap to hide password")
    }
    
    // MARK: - Validation Error View
    
    private func validationErrorView(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
    
    // MARK: - Password Strength View
    
    private var passwordStrengthView: some View {
        let passwordValidation = Validation.validatePassword(text)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(passwordValidation.strength.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(passwordValidation.strength))
                
                Spacer()
                
                Text("\(Int(passwordValidation.strengthPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Strength Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color(passwordValidation.strength))
                        .frame(
                            width: geometry.size.width * passwordValidation.strengthPercentage,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.3), value: passwordValidation.strengthPercentage)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            
            // Requirements List
            VStack(alignment: .leading, spacing: 4) {
                ForEach(passwordValidation.requirements.indices, id: \.self) { index in
                    let requirement = passwordValidation.requirements[index]
                    
                    HStack(spacing: 6) {
                        Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(requirement.isMet ? .green : .secondary)
                        
                        Text(requirement.description)
                            .font(.caption)
                            .foregroundColor(requirement.isMet ? .primary : .secondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if let validationResult = validationResult {
            switch validationResult {
            case .valid:
                return isFocused ? .green : .gray.opacity(0.3)
            case .invalid:
                return .red
            }
        } else if isFocused {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if validationResult != nil || isFocused {
            return 2
        } else {
            return 1
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return Color.clear
        } else {
            return Color(UIColor.systemBackground)
        }
    }
}

// MARK: - Convenience Initializers

extension SecureTextField {
    
    // Standard password field
    static func password(
        title: String = "Password",
        placeholder: String = "Enter your password",
        text: Binding<String>,
        showStrengthIndicator: Bool = false,
        validationResult: ValidationResult? = nil
    ) -> SecureTextField {
        SecureTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            showPasswordToggle: true,
            showStrengthIndicator: showStrengthIndicator,
            validationResult: validationResult,
            textContentType: .password,
            accessibilityLabel: "Password field",
            accessibilityHint: "Enter your password securely"
        )
    }
    
    // New password field with strength indicator
    static func newPassword(
        title: String = "Create Password",
        placeholder: String = "Create a secure password",
        text: Binding<String>,
        validationResult: ValidationResult? = nil
    ) -> SecureTextField {
        SecureTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            showPasswordToggle: true,
            showStrengthIndicator: true,
            validationResult: validationResult,
            textContentType: .newPassword,
            accessibilityLabel: "New password field",
            accessibilityHint: "Create a secure password with at least 8 characters"
        )
    }
    
    // Confirm password field
    static func confirmPassword(
        title: String = "Confirm Password",
        placeholder: String = "Confirm your password",
        text: Binding<String>,
        validationResult: ValidationResult? = nil
    ) -> SecureTextField {
        SecureTextField(
            title: title,
            placeholder: placeholder,
            text: text,
            showPasswordToggle: true,
            showStrengthIndicator: false,
            validationResult: validationResult,
            textContentType: .newPassword,
            accessibilityLabel: "Confirm password field",
            accessibilityHint: "Re-enter your password to confirm"
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        SecureTextField.password(
            text: .constant(""),
            validationResult: .invalid("Password is required")
        )
        
        SecureTextField.newPassword(
            text: .constant("MySecurePass123!"),
            validationResult: .valid
        )
        
        SecureTextField.confirmPassword(
            text: .constant("MySecurePass123!")
        )
    }
    .padding()
}