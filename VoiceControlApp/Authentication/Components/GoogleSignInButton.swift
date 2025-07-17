import SwiftUI

// MARK: - Button Size Options

enum ButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 50
        case .large: return 60
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
    
    var progressScale: CGFloat {
        switch self {
        case .small: return 0.7
        case .medium: return 0.8
        case .large: return 0.9
        }
    }
}

// MARK: - Google Sign-In Button Component

struct GoogleSignInButton: View {
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool
    
    // Customization options following LoadingButton patterns
    var size: ButtonSize = .medium
    var hapticFeedback: Bool = true
    
    init(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        size: ButtonSize = .medium,
        hapticFeedback: Bool = true
    ) {
        self.action = action
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.size = size
        self.hapticFeedback = hapticFeedback
    }
    
    var body: some View {
        Button(action: performAction) {
            HStack(spacing: 12) {
                if isLoading {
                    // Loading spinner matching LoadingButton pattern
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(size.progressScale)
                } else {
                    // Google logo
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    Text("Continue with Google")
                        .fontWeight(.medium)
                        .font(.system(size: size.fontSize))
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundView)
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
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .stroke(isEnabled ? Color.primary.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(Color(UIColor.systemBackground))
            )
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
            return "Signing in with Google"
        } else {
            return "Sign in with Google"
        }
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Please wait while Google sign-in completes"
        } else if !isEnabled {
            return "Google sign-in is currently disabled"
        } else {
            return "Opens Google sign-in in browser for secure authentication"
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

// MARK: - Convenience Initializers

extension GoogleSignInButton {
    
    /// Creates a Google Sign-In button with default styling
    static func standard(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) -> GoogleSignInButton {
        GoogleSignInButton(
            action: action,
            isLoading: isLoading,
            isEnabled: isEnabled,
            size: .medium
        )
    }
    
    /// Creates a compact Google Sign-In button
    static func compact(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) -> GoogleSignInButton {
        GoogleSignInButton(
            action: action,
            isLoading: isLoading,
            isEnabled: isEnabled,
            size: .small
        )
    }
    
    /// Creates a large Google Sign-In button
    static func large(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) -> GoogleSignInButton {
        GoogleSignInButton(
            action: action,
            isLoading: isLoading,
            isEnabled: isEnabled,
            size: .large
        )
    }
}

// MARK: - Google Branding Compliance

extension GoogleSignInButton {
    
    /// Creates a Google Sign-In button with official Google branding colors
    /// Note: This requires adding official Google logo assets to the project
    static func branded(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isEnabled: Bool = true
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    // Official Google "G" logo would go here
                    // For now using system globe icon
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Continue with Google")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isEnabled ? Color.blue : Color.gray.opacity(0.5))
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityLabel("Sign in with Google")
        .accessibilityHint("Opens Google sign-in in browser")
    }
}

// MARK: - Preview

#Preview("Google Sign-In Buttons") {
    VStack(spacing: 20) {
        // Standard button states
        GoogleSignInButton.standard {
            print("Google Sign-In tapped")
        }
        
        GoogleSignInButton.standard(
            action: { print("Loading...") },
            isLoading: true
        )
        
        GoogleSignInButton.standard(
            action: { print("Disabled") },
            isEnabled: false
        )
        
        // Size variants
        GoogleSignInButton.compact {
            print("Compact tapped")
        }
        
        GoogleSignInButton.large {
            print("Large tapped")
        }
        
        // Branded version
        GoogleSignInButton.branded {
            print("Branded tapped")
        }
        
        Spacer()
    }
    .padding()
}