import SwiftUI

// MARK: - Loading Button Component

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    // Customization options
    var style: LoadingButtonStyle = .primary
    var size: LoadingButtonSize = .medium
    var hapticFeedback: Bool = true
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: LoadingButtonStyle = .primary,
        size: LoadingButtonSize = .medium,
        hapticFeedback: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.size = size
        self.hapticFeedback = hapticFeedback
        self.action = action
    }
    
    var body: some View {
        Button(action: performAction) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(size.progressScale)
                } else {
                    Text(title)
                        .fontWeight(style.fontWeight)
                        .font(size.font)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundView)
            .foregroundColor(style.foregroundColor)
            .opacity(effectiveOpacity)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(isEnabled ? Color.blue : Color.gray.opacity(0.3))
        case .secondary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(isEnabled ? Color.blue : Color.gray, lineWidth: 2)
        case .destructive:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(isEnabled ? Color.red : Color.gray.opacity(0.3))
        case .success:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(isEnabled ? Color.green : Color.gray.opacity(0.3))
        case .ghost:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(Color.clear)
        }
    }
    
    // MARK: - Computed Properties
    
    private var effectiveOpacity: Double {
        if isLoading {
            return 0.8
        } else if !isEnabled {
            return 0.6
        } else {
            return 1.0
        }
    }
    
    private var accessibilityLabel: String {
        if isLoading {
            return "\(title), loading"
        } else {
            return title
        }
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Please wait while the action completes"
        } else if !isEnabled {
            return "Button is currently disabled"
        } else {
            return "Tap to \(title.lowercased())"
        }
    }
    
    // MARK: - Actions
    
    private func performAction() {
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        action()
    }
}

// MARK: - Loading Button Styles

enum LoadingButtonStyle {
    case primary
    case secondary
    case destructive
    case success
    case ghost
    
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success:
            return .white
        case .secondary:
            return .blue
        case .ghost:
            return .primary
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .primary, .destructive, .success:
            return .semibold
        case .secondary, .ghost:
            return .medium
        }
    }
}

// MARK: - Loading Button Sizes

enum LoadingButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 50
        case .large:
            return 56
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return .subheadline
        case .medium:
            return .body
        case .large:
            return .headline
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }
    
    var progressScale: CGFloat {
        switch self {
        case .small:
            return 0.7
        case .medium:
            return 0.8
        case .large:
            return 1.0
        }
    }
}

// MARK: - Convenience Initializers

extension LoadingButton {
    
    // Primary button
    static func primary(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title,
            isLoading: isLoading,
            isEnabled: isEnabled,
            style: .primary,
            action: action
        )
    }
    
    // Secondary button
    static func secondary(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title,
            isLoading: isLoading,
            isEnabled: isEnabled,
            style: .secondary,
            action: action
        )
    }
    
    // Destructive button
    static func destructive(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title,
            isLoading: isLoading,
            isEnabled: isEnabled,
            style: .destructive,
            action: action
        )
    }
    
    // Success button
    static func success(
        _ title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> LoadingButton {
        LoadingButton(
            title,
            isLoading: isLoading,
            isEnabled: isEnabled,
            style: .success,
            action: action
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        LoadingButton.primary("Sign In", isLoading: false) {
            print("Sign In tapped")
        }
        
        LoadingButton.primary("Loading...", isLoading: true) {
            print("Loading...")
        }
        
        LoadingButton.secondary("Secondary", isEnabled: true) {
            print("Secondary tapped")
        }
        
        LoadingButton.destructive("Delete", isEnabled: false) {
            print("Delete tapped")
        }
        
        LoadingButton.success("Success") {
            print("Success tapped")
        }
        
        LoadingButton("Ghost", style: .ghost, size: .small) {
            print("Ghost tapped")
        }
    }
    .padding()
}