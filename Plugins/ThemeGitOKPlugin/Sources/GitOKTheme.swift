import SwiftUI
import GitOKCoreKit

struct GitOKTheme: GitOKAppChromeTheme {
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
        Color.adaptive(light: "1F2937", dark: "FFFFFF")
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

extension GitOKTheme {
    static let repository = GitOKTheme(
        identifier: "repository",
        displayName: "默认",
        compactName: "默认",
        description: GitOKThemePluginLocalization.string("Default GitOK theme"),
        iconName: "folder.badge.gearshape",
        iconColor: Color.adaptive(light: "2563EB", dark: "58A6FF"),
        appearanceKind: .system,
        deep: Color.adaptive(light: "F3F4F6", dark: "0D1117"),
        medium: Color.adaptive(light: "FFFFFF", dark: "161B22"),
        light: Color.adaptive(light: "E5E7EB", dark: "21262D"),
        primary: Color.adaptive(light: "2563EB", dark: "58A6FF"),
        secondary: Color.adaptive(light: "059669", dark: "3FB950"),
        tertiary: Color.adaptive(light: "7C3AED", dark: "BC8CFF"),
        text: Color.adaptive(light: "1F2937", dark: "F0F6FC"),
        secondaryText: Color.adaptive(light: "6B7280", dark: "C9D1D9"),
        tertiaryText: Color.adaptive(light: "9CA3AF", dark: "8B949E")
    )
}
