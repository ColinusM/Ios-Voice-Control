import SwiftUI

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let error: AuthenticationError?
    let onDismiss: (() -> Void)?
    let onRetry: (() -> Void)?
    
    init(
        isPresented: Binding<Bool>,
        error: AuthenticationError?,
        onDismiss: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Authentication Error",
                isPresented: $isPresented,
                presenting: error
            ) { error in
                alertButtons(for: error)
            } message: { error in
                alertMessage(for: error)
            }
    }
    
    // MARK: - Alert Buttons
    
    @ViewBuilder
    private func alertButtons(for error: AuthenticationError) -> some View {
        // Retry button for retryable errors
        if shouldShowRetryButton(for: error), let onRetry = onRetry {
            Button("Retry") {
                onRetry()
            }
        }
        
        // Settings button for configuration errors
        if shouldShowSettingsButton(for: error) {
            Button("Settings") {
                openAppSettings()
            }
        }
        
        // Help button for complex errors
        if shouldShowHelpButton(for: error) {
            Button("Help") {
                openHelp()
            }
        }
        
        // Dismiss button (always present)
        Button("OK") {
            onDismiss?()
        }
    }
    
    // MARK: - Alert Message
    
    private func alertMessage(for error: AuthenticationError) -> Text {
        var message = error.localizedDescription
        
        if let recoverySuggestion = error.recoverySuggestion {
            message += "\n\n" + recoverySuggestion
        }
        
        return Text(message)
    }
    
    // MARK: - Button Logic
    
    private func shouldShowRetryButton(for error: AuthenticationError) -> Bool {
        switch error {
        case .networkError, .tooManyRequests, .unknownError:
            return true
        default:
            return false
        }
    }
    
    private func shouldShowSettingsButton(for error: AuthenticationError) -> Bool {
        switch error {
        case .biometricUnavailable:
            return true
        default:
            return false
        }
    }
    
    private func shouldShowHelpButton(for error: AuthenticationError) -> Bool {
        switch error {
        case .operationNotAllowed, .userDisabled, .unknownError:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Actions
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
    
    private func openHelp() {
        guard let helpUrl = URL(string: "https://support.voicecontrol.app"),
              UIApplication.shared.canOpenURL(helpUrl) else {
            return
        }
        
        UIApplication.shared.open(helpUrl)
    }
}

// MARK: - Inline Error Display Modifier

struct InlineErrorModifier: ViewModifier {
    let error: AuthenticationError?
    let style: InlineErrorStyle
    
    init(error: AuthenticationError?, style: InlineErrorStyle = .default) {
        self.error = error
        self.style = style
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content
            
            if let error = error {
                inlineErrorView(error)
            }
        }
    }
    
    @ViewBuilder
    private func inlineErrorView(_ error: AuthenticationError) -> some View {
        HStack(alignment: .top, spacing: style.iconSpacing) {
            Image(systemName: style.iconName)
                .foregroundColor(style.iconColor)
                .font(style.iconFont)
            
            VStack(alignment: .leading, spacing: 4) {
                if style.showTitle {
                    Text(style.titleText)
                        .font(style.titleFont)
                        .fontWeight(.medium)
                        .foregroundColor(style.titleColor)
                }
                
                Text(error.localizedDescription)
                    .font(style.messageFont)
                    .foregroundColor(style.messageColor)
                    .multilineTextAlignment(.leading)
                
                if style.showRecoverySuggestion,
                   let recoverySuggestion = error.recoverySuggestion {
                    Text(recoverySuggestion)
                        .font(style.suggestionFont)
                        .foregroundColor(style.suggestionColor)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(style.borderColor, lineWidth: style.borderWidth)
        )
    }
}

// MARK: - Inline Error Styles

struct InlineErrorStyle {
    let iconName: String
    let iconColor: Color
    let iconFont: Font
    let iconSpacing: CGFloat
    let showTitle: Bool
    let titleText: String
    let titleFont: Font
    let titleColor: Color
    let messageFont: Font
    let messageColor: Color
    let showRecoverySuggestion: Bool
    let suggestionFont: Font
    let suggestionColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    static let `default` = InlineErrorStyle(
        iconName: "exclamationmark.triangle.fill",
        iconColor: .red,
        iconFont: .caption,
        iconSpacing: 8,
        showTitle: false,
        titleText: "Error",
        titleFont: .caption,
        titleColor: .red,
        messageFont: .caption,
        messageColor: .red,
        showRecoverySuggestion: false,
        suggestionFont: .caption2,
        suggestionColor: .secondary,
        backgroundColor: Color.red.opacity(0.1),
        borderColor: Color.red.opacity(0.3),
        borderWidth: 1,
        cornerRadius: 8,
        padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    )
    
    static let detailed = InlineErrorStyle(
        iconName: "exclamationmark.triangle.fill",
        iconColor: .red,
        iconFont: .subheadline,
        iconSpacing: 12,
        showTitle: true,
        titleText: "Authentication Error",
        titleFont: .subheadline,
        titleColor: .red,
        messageFont: .subheadline,
        messageColor: .red,
        showRecoverySuggestion: true,
        suggestionFont: .caption,
        suggestionColor: .secondary,
        backgroundColor: Color.red.opacity(0.1),
        borderColor: Color.red.opacity(0.3),
        borderWidth: 1,
        cornerRadius: 8,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    )
    
    static let minimal = InlineErrorStyle(
        iconName: "exclamationmark.circle.fill",
        iconColor: .red,
        iconFont: .caption2,
        iconSpacing: 6,
        showTitle: false,
        titleText: "",
        titleFont: .caption,
        titleColor: .red,
        messageFont: .caption,
        messageColor: .red,
        showRecoverySuggestion: false,
        suggestionFont: .caption2,
        suggestionColor: .secondary,
        backgroundColor: Color.clear,
        borderColor: Color.clear,
        borderWidth: 0,
        cornerRadius: 0,
        padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    )
}

// MARK: - Success Message Modifier

struct SuccessMessageModifier: ViewModifier {
    let message: String?
    let isPresented: Bool
    let autoDismiss: Bool
    let duration: TimeInterval
    
    @State private var workItem: DispatchWorkItem?
    
    init(
        message: String?,
        isPresented: Bool,
        autoDismiss: Bool = true,
        duration: TimeInterval = 3.0
    ) {
        self.message = message
        self.isPresented = isPresented
        self.autoDismiss = autoDismiss
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content
            
            if isPresented, let message = message {
                successMessageView(message)
                    .onAppear {
                        if autoDismiss {
                            scheduleAutoDismiss()
                        }
                    }
                    .onDisappear {
                        workItem?.cancel()
                    }
            }
        }
    }
    
    @ViewBuilder
    private func successMessageView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.green)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func scheduleAutoDismiss() {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem {
            // Auto-dismiss logic would be handled by parent view
        }
        
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: newWorkItem)
    }
}

// MARK: - View Extensions

extension View {
    
    // Error alert
    func errorAlert(
        isPresented: Binding<Bool>,
        error: AuthenticationError?,
        onDismiss: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(
            isPresented: isPresented,
            error: error,
            onDismiss: onDismiss,
            onRetry: onRetry
        ))
    }
    
    // Inline error display
    func inlineError(
        _ error: AuthenticationError?,
        style: InlineErrorStyle = .default
    ) -> some View {
        modifier(InlineErrorModifier(error: error, style: style))
    }
    
    // Success message display
    func successMessage(
        _ message: String?,
        isPresented: Bool,
        autoDismiss: Bool = true,
        duration: TimeInterval = 3.0
    ) -> some View {
        modifier(SuccessMessageModifier(
            message: message,
            isPresented: isPresented,
            autoDismiss: autoDismiss,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        Text("Content with error")
            .inlineError(.invalidCredential, style: .default)
        
        Text("Content with detailed error")
            .inlineError(.networkError, style: .detailed)
        
        Text("Content with minimal error")
            .inlineError(.weakPassword, style: .minimal)
        
        Text("Content with success")
            .successMessage("Account created successfully!", isPresented: true)
    }
    .padding()
}