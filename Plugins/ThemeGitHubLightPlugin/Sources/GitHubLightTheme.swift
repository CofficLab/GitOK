import SwiftUI
import GitOKCoreKit

struct GitHubLightTheme: GitOKAppChromeTheme {
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
                        .fill(primary.opacity(0.05))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .fill(secondary.opacity(0.04))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(0.04))
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

extension GitHubLightTheme {
    static let githubLight = GitHubLightTheme(
        identifier: "github-light",
        displayName: "GitHub Light",
        compactName: "GitHub",
        description: "Clean light theme inspired by GitHub's default interface",
        iconName: "globe",
        iconColor: Color(hex: "0969DA"),
        appearanceKind: .light,
        deep: Color(hex: "F6F8FA"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "D8DEE4"),
        primary: Color(hex: "0969DA"),
        secondary: Color(hex: "1A7F37"),
        tertiary: Color(hex: "9A6700"),
        text: Color(hex: "24292F"),
        secondaryText: Color(hex: "57606A"),
        tertiaryText: Color(hex: "8C959F")
    )
}
