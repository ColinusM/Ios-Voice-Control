import SwiftUI

// MARK: - Color Extensions for App Theme

extension Color {
    
    // MARK: - App Brand Colors
    
    /// Primary brand color (blue)
    static let appPrimary = Color.blue
    
    /// Secondary brand color
    static let appSecondary = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    /// Accent color for highlights
    static let appAccent = Color(red: 0.0, green: 0.8, blue: 0.4)
    
    // MARK: - Authentication Colors
    
    /// Success color for authentication
    static let authSuccess = Color.green
    
    /// Error color for authentication
    static let authError = Color.red
    
    /// Warning color for authentication
    static let authWarning = Color.orange
    
    /// Info color for authentication
    static let authInfo = Color.blue
    
    // MARK: - Background Colors
    
    /// Primary background color (adapts to light/dark mode)
    static let backgroundPrimary = Color(UIColor.systemBackground)
    
    /// Secondary background color
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    
    /// Tertiary background color
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    /// Grouped background color
    static let backgroundGrouped = Color(UIColor.systemGroupedBackground)
    
    // MARK: - Text Colors
    
    /// Primary text color
    static let textPrimary = Color(UIColor.label)
    
    /// Secondary text color
    static let textSecondary = Color(UIColor.secondaryLabel)
    
    /// Tertiary text color
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    /// Quaternary text color
    static let textQuaternary = Color(UIColor.quaternaryLabel)
    
    // MARK: - Border Colors
    
    /// Light border color
    static let borderLight = Color(UIColor.separator)
    
    /// Medium border color
    static let borderMedium = Color(UIColor.opaqueSeparator)
    
    /// Focus border color (for input fields)
    static let borderFocus = Color.blue
    
    /// Error border color
    static let borderError = Color.red
    
    /// Success border color
    static let borderSuccess = Color.green
    
    // MARK: - Authentication Specific Colors
    
    /// Background for authentication screens
    static let authBackground = Color(
        light: Color(red: 0.98, green: 0.99, blue: 1.0),
        dark: Color(UIColor.systemBackground)
    )
    
    /// Card background for authentication forms
    static let authCardBackground = Color(UIColor.systemBackground)
    
    /// Input field background
    static let inputBackground = Color(UIColor.systemBackground)
    
    /// Input field focused background
    static let inputFocusedBackground = Color(UIColor.systemBackground)
    
    // MARK: - Status Colors
    
    /// Online/Active status
    static let statusOnline = Color.green
    
    /// Offline/Inactive status
    static let statusOffline = Color.gray
    
    /// Pending status
    static let statusPending = Color.orange
    
    /// Processing status
    static let statusProcessing = Color.blue
    
    // MARK: - Gradient Colors
    
    /// Primary gradient
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [Color.blue, Color.purple]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success gradient
    static let gradientSuccess = LinearGradient(
        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Error gradient
    static let gradientError = LinearGradient(
        gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Authentication background gradient
    static let gradientAuthBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue.opacity(0.1),
            Color.white.opacity(0.8)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Password Strength Colors
    
    /// Very weak password
    static let passwordVeryWeak = Color.red
    
    /// Weak password
    static let passwordWeak = Color.orange
    
    /// Fair password
    static let passwordFair = Color.yellow
    
    /// Good password
    static let passwordGood = Color.blue
    
    /// Strong password
    static let passwordStrong = Color.green
    
    // MARK: - Biometric Colors
    
    /// Face ID color
    static let faceIDColor = Color.blue
    
    /// Touch ID color
    static let touchIDColor = Color.green
    
    /// Biometric error color
    static let biometricError = Color.red
    
    /// Biometric success color
    static let biometricSuccess = Color.green
}

// MARK: - Color Utilities

extension Color {
    
    /// Creates a color that adapts to light and dark mode
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    /// Creates a color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Returns hex string representation of the color
    var hexString: String {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return "#000000"
        }
        
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// Returns a lighter version of the color
    func lighter(by percentage: Double = 0.2) -> Color {
        return Color(UIColor(self).lighter(by: percentage))
    }
    
    /// Returns a darker version of the color
    func darker(by percentage: Double = 0.2) -> Color {
        return Color(UIColor(self).darker(by: percentage))
    }
    
    /// Returns the contrasting color (black or white)
    var contrastingColor: Color {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    
    /// Returns a lighter version of the color
    func lighter(by percentage: Double = 0.2) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }
    
    /// Returns a darker version of the color
    func darker(by percentage: Double = 0.2) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }
    
    /// Adjusts the brightness of the color
    private func adjustBrightness(by percentage: Double) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        brightness = max(0, min(1, brightness + CGFloat(percentage)))
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
}

// MARK: - Theme Support

struct AppTheme {
    
    // MARK: - Color Schemes
    
    struct Light {
        static let primary = Color.blue
        static let background = Color.white
        static let surface = Color.white
        static let onPrimary = Color.white
        static let onBackground = Color.black
        static let onSurface = Color.black
    }
    
    struct Dark {
        static let primary = Color.blue
        static let background = Color.black
        static let surface = Color(UIColor.systemGray6)
        static let onPrimary = Color.white
        static let onBackground = Color.white
        static let onSurface = Color.white
    }
    
    // MARK: - Dynamic Colors
    
    static let primary = Color(light: Light.primary, dark: Dark.primary)
    static let background = Color(light: Light.background, dark: Dark.background)
    static let surface = Color(light: Light.surface, dark: Dark.surface)
    static let onPrimary = Color(light: Light.onPrimary, dark: Dark.onPrimary)
    static let onBackground = Color(light: Light.onBackground, dark: Dark.onBackground)
    static let onSurface = Color(light: Light.onSurface, dark: Dark.onSurface)
}

// MARK: - Color Accessibility

extension Color {
    
    /// Checks if the color meets WCAG AA contrast requirements
    func meetsContrastRequirement(against background: Color, level: ContrastLevel = .AA) -> Bool {
        let ratio = contrastRatio(with: background)
        
        switch level {
        case .AA:
            return ratio >= 4.5
        case .AAA:
            return ratio >= 7.0
        }
    }
    
    /// Calculates the contrast ratio between two colors
    func contrastRatio(with other: Color) -> Double {
        let luminance1 = relativeLuminance
        let luminance2 = other.relativeLuminance
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculates the relative luminance of the color
    private var relativeLuminance: Double {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let adjust: (CGFloat) -> Double = { component in
            let value = Double(component)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        
        return 0.2126 * adjust(red) + 0.7152 * adjust(green) + 0.0722 * adjust(blue)
    }
}

enum ContrastLevel {
    case AA
    case AAA
}