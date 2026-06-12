import SwiftUI
import GitOKCoreKit

struct XcodeLightTheme: GitOKAppChromeTheme {
    let identifier: String
    let displayName: String
    let compactName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let appearanceKind: ThemeAppearanceKind
    let deep: Color
    let medium: Color
    let light: Color
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let text: Color
    let secondaryText: Color
    let tertiaryText: Color

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (primary, secondary, tertiary)
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (deep, medium, light)
    }

    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            subtle: primary.opacity(0.08),
            medium: secondary.opacity(0.10),
            intense: tertiary.opacity(0.12)
        )
    }

    func workspaceBackgroundColor() -> Color {
        medium
    }

    func sidebarBackgroundColor() -> Color {
        deep
    }

    func sidebarSelectionColor() -> Color {
        primary.opacity(0.14)
    }

    func sidebarSelectionTextColor() -> Color {
        Color(hex: "111827")
    }

    func workspaceTextColor() -> Color {
        text
    }

    func workspaceSecondaryTextColor() -> Color {
        secondaryText
    }

    func workspaceTertiaryTextColor() -> Color {
        tertiaryText
    }

    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView {
        AnyView(
            ZStack {
                backgroundGradient()

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(0.10))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .fill(secondary.opacity(0.08))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(0.08))
                        .frame(width: 1)
                    Spacer()
                    Rectangle()
                        .fill(tertiary.opacity(0.035))
                        .frame(width: 1)
                }
                .padding(.vertical, 20)
            }
        )
    }
}

extension XcodeLightTheme {
    static let xcodeLight = XcodeLightTheme(
        identifier: "xcode-light",
        displayName: "Xcode Light",
        compactName: "Xcode",
        description: "Bright macOS-native theme inspired by Xcode Light",
        iconName: "hammer",
        iconColor: Color(hex: "0A84FF"),
        appearanceKind: .light,
        deep: Color(hex: "F2F6FC"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "DDE7F5"),
        primary: Color(hex: "0A84FF"),
        secondary: Color(hex: "30D158"),
        tertiary: Color(hex: "FF9F0A"),
        text: Color(hex: "1D1D1F"),
        secondaryText: Color(hex: "515A66"),
        tertiaryText: Color(hex: "8B95A3")
    )
}

