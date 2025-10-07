import SwiftUI

// MARK: - Color Theme (CleanMyMac-inspired)

extension Color {
    // Background colors
    static let appBackground = Color(red: 0.12, green: 0.08, blue: 0.28) // Deep purple #1E1448
    static let cardBackground = Color(red: 0.18, green: 0.12, blue: 0.35) // Lighter purple #2D1F59
    static let cardBackgroundHover = Color(red: 0.22, green: 0.15, blue: 0.40) // Hover state
    static let inputBackground = Color(red: 0.14, green: 0.10, blue: 0.32) // Input fields
    
    // Accent colors
    static let accentBlue = Color(red: 0.4, green: 0.7, blue: 1.0) // Bright blue
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.3) // Warm orange
    static let accentGreen = Color(red: 0.5, green: 0.8, blue: 0.4) // Fresh green
    static let accentPurple = Color(red: 0.6, green: 0.4, blue: 1.0) // Vibrant purple
    static let accentYellow = Color(red: 1.0, green: 0.8, blue: 0.2) // Gold/yellow
    
    // Status colors
    static let statusSuccess = Color(red: 0.45, green: 0.85, blue: 0.55) // Green
    static let statusWarning = Color(red: 1.0, green: 0.75, blue: 0.2) // Yellow
    static let statusError = Color(red: 1.0, green: 0.4, blue: 0.4) // Red
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func card(cornerRadius: CGFloat = 14) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .accentBlue) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(color)
            )
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 4 : 8, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundStyle(Color.textPrimary)
            .shadow(color: Color.black.opacity(0.1), radius: configuration.isPressed ? 3 : 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Premium Input Field Style

struct PremiumTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentBlue : Color.white.opacity(0.15), lineWidth: 1.5)
            )
            .shadow(color: isFocused ? Color.accentBlue.opacity(0.2) : Color.clear, radius: 8, y: 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

extension View {
    func premiumTextField() -> some View {
        self.textFieldStyle(PremiumTextFieldStyle())
    }
}

// MARK: - Smooth Transitions

extension AnyTransition {
    static var smoothScale: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }
    
    static var smoothSlide: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

