import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

enum Theme {
    static let accent = Color(light: 0xE4515A, dark: 0xF26A72)
    static let accentDeep = Color(light: 0xB93340, dark: 0xC9434E)
    static let accentSoft = Color(light: 0xFCEAEB, dark: 0x3A1D22)
    static let background = Color(light: 0xF6F3EF, dark: 0x0B0B0F)
    static let backgroundRaised = Color(light: 0xFBF9F6, dark: 0x111116)
    static let surface = Color(light: 0xFFFFFF, dark: 0x17171D)
    static let surfaceAlt = Color(light: 0xF0ECE6, dark: 0x202028)
    static let textPrimary = Color(light: 0x1A171B, dark: 0xF6F2ED)
    static let textSecondary = Color(light: 0x6D6870, dark: 0x9C97A2)
    static let textTertiary = Color(light: 0x9A949C, dark: 0x6C6873)
    static let separator = Color(light: 0xE8E2DB, dark: 0x282830)
    static let teal = Color(light: 0x2F9C8E, dark: 0x55C5B5)
    static let blue = Color(light: 0x527FE5, dark: 0x7C9DF0)
    static let amber = Color(light: 0xE0A03A, dark: 0xF0B75B)
    static let purple = Color(light: 0x8B6BD9, dark: 0xA98AEC)
    static let green = Color(light: 0x4D9C5C, dark: 0x6BC47C)
    static let orange = Color(light: 0xE07B3F, dark: 0xF0915A)
    static let pink = Color(light: 0xD95C9A, dark: 0xEA79B3)

    static let heartGradient = LinearGradient(
        colors: [Color(hex: 0xF0666D), Color(hex: 0xC02D42)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let calmGradient = LinearGradient(
        colors: [Color(hex: 0x2E9D91), Color(hex: 0x1D6A73)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let duskGradient = LinearGradient(
        colors: [Color(hex: 0x7B6AD6), Color(hex: 0x46358F)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xF0B75B), Color(hex: 0xCB7D28)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func gradient(for index: Int) -> LinearGradient {
        switch index % 5 {
        case 0: return heartGradient
        case 1: return calmGradient
        case 2: return duskGradient
        case 3: return goldGradient
        default: return LinearGradient(colors: [Color(hex: 0x5B8DEF), Color(hex: 0x3653B3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    static func primaryColor(for index: Int) -> Color {
        switch index % 5 {
        case 0: return Color(hex: 0xF0666D)
        case 1: return Color(hex: 0x2E9D91)
        case 2: return Color(hex: 0x7B6AD6)
        case 3: return Color(hex: 0xF0B75B)
        default: return Color(hex: 0x5B8DEF)
        }
    }
}

extension View {
    func cardSurface(padding: CGFloat = 18, radius: CGFloat = 24) -> some View {
        self
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 18, x: 0, y: 10)
    }

    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var foreground: Color = .white
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(color)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Theme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
