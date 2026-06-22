import SwiftUI
import GitOKCoreKit

struct OneDarkTheme: GitOKAppChromeTheme {
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
            subtle: primary.opacity(0.12),
            medium: secondary.opacity(0.16),
            intense: tertiary.opacity(0.18)
        )
    }

    func workspaceBackgroundColor() -> Color {
        medium
    }

    func sidebarBackgroundColor() -> Color {
        deep
    }

    func sidebarSelectionColor() -> Color {
        primary.opacity(0.24)
    }

    func sidebarSelectionTextColor() -> Color {
        .white
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
                        .fill(tertiary.opacity(0.06))
                        .frame(width: 1)
                }
                .padding(.vertical, 20)
            }
        )
    }
}

extension OneDarkTheme {
    static let oneDark = OneDarkTheme(
        identifier: "one-dark",
        displayName: "One Dark",
        compactName: "One",
        description: OneDarkThemePluginLocalization.string("Classic editor dark theme"),
        iconName: "chevron.left.forwardslash.chevron.right",
        iconColor: Color(hex: "61AFEF"),
        appearanceKind: .dark,
        deep: Color(hex: "1E222A"),
        medium: Color(hex: "282C34"),
        light: Color(hex: "353B45"),
        primary: Color(hex: "61AFEF"),
        secondary: Color(hex: "98C379"),
        tertiary: Color(hex: "E5C07B"),
        text: Color(hex: "ABB2BF"),
        secondaryText: Color(hex: "C8CCD4"),
        tertiaryText: Color(hex: "7F8794")
    )
}

