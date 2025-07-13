import SwiftUI

// MARK: - SwiftUI View Extensions

extension View {
    
    // MARK: - Keyboard Handling
    
    /// Dismisses the keyboard when tapping outside of text fields
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                          to: nil, from: nil, for: nil)
        }
    }
    
    /// Hides the keyboard when a specific condition is met
    func hideKeyboard(when condition: Bool) -> some View {
        onChange(of: condition) { _, newValue in
            if newValue {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                              to: nil, from: nil, for: nil)
            }
        }
    }
    
    // MARK: - Conditional Modifiers
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers
    @ViewBuilder
    func `if`<TrueTransform: View, FalseTransform: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueTransform,
        ifFalse: (Self) -> FalseTransform
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
    
    // MARK: - Loading States
    
    /// Shows a loading overlay
    func loading(_ isLoading: Bool) -> some View {
        overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                }
            }
        )
    }
    
    /// Shows a loading overlay with text
    func loading(_ isLoading: Bool, text: String) -> some View {
        overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            
                            Text(text)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
        )
    }
    
    // MARK: - Authentication Flow Helpers
    
    /// Applies authentication-specific styling
    func authenticationStyle() -> some View {
        background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .dismissKeyboardOnTap()
    }
    
    /// Adds authentication form styling
    func authFormStyle() -> some View {
        padding(.horizontal, 32)
        .padding(.vertical, 24)
    }
    
    // MARK: - Accessibility
    
    /// Adds semantic accessibility traits
    func accessibilityInputField(
        label: String,
        hint: String? = nil,
        isRequired: Bool = false
    ) -> some View {
        accessibilityLabel(label + (isRequired ? " (required)" : ""))
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(.isStaticText)
    }
    
    /// Adds button accessibility traits
    func accessibilityButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
            .accessibilityAddTraits(.isButton)
            .if(!isEnabled) { view in
                view.accessibilityAddTraits(.isNotEnabled)
            }
    }
    
    // MARK: - Haptic Feedback
    
    /// Adds haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Adds haptic feedback with custom action
    func hapticFeedback<T: Equatable>(
        on value: T,
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light
    ) -> some View {
        onChange(of: value) { _, _ in
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Card Styling
    
    /// Applies card-like styling
    func cardStyle(
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.1
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: shadowRadius, x: 0, y: 2)
        )
    }
    
    /// Applies elevated card styling
    func elevatedCardStyle() -> some View {
        background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Border Styling
    
    /// Adds a border with custom color and width
    func border(_ color: Color, width: CGFloat = 1, cornerRadius: CGFloat = 8) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Adds a validation-aware border
    func validationBorder(
        _ validation: ValidationResult?,
        focused: Bool = false,
        cornerRadius: CGFloat = 8
    ) -> some View {
        let borderColor: Color = {
            if let validation = validation {
                switch validation {
                case .valid:
                    return focused ? .green : .gray.opacity(0.3)
                case .invalid:
                    return .red
                }
            } else if focused {
                return .blue
            } else {
                return .gray.opacity(0.3)
            }
        }()
        
        let borderWidth: CGFloat = (validation != nil || focused) ? 2 : 1
        
        return border(borderColor, width: borderWidth, cornerRadius: cornerRadius)
    }
    
    // MARK: - Animation Helpers
    
    /// Adds a shake animation
    func shake(offset: CGFloat = 5) -> some View {
        modifier(ShakeModifier(offset: offset))
    }
    
    /// Adds a pulse animation
    func pulse(scale: CGFloat = 1.1) -> some View {
        modifier(PulseModifier(scale: scale))
    }
    
    // MARK: - Safe Area Handling
    
    /// Adds safe area padding only if needed
    func safePadding(_ edges: Edge.Set = .all) -> some View {
        modifier(SafePaddingModifier(edges: edges))
    }
}

// MARK: - Custom Modifiers

struct ShakeModifier: ViewModifier {
    let offset: CGFloat
    @State private var isShaking = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? offset : 0)
            .animation(
                isShaking ? 
                Animation.linear(duration: 0.1).repeatCount(3, autoreverses: true) :
                Animation.default,
                value: isShaking
            )
            .onAppear {
                isShaking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShaking = false
                }
            }
    }
}

struct PulseModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct SafePaddingModifier: ViewModifier {
    let edges: Edge.Set
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.top, edges.contains(.top) ? geometry.safeAreaInsets.top : 0)
                .padding(.bottom, edges.contains(.bottom) ? geometry.safeAreaInsets.bottom : 0)
                .padding(.leading, edges.contains(.leading) ? geometry.safeAreaInsets.leading : 0)
                .padding(.trailing, edges.contains(.trailing) ? geometry.safeAreaInsets.trailing : 0)
        }
    }
}