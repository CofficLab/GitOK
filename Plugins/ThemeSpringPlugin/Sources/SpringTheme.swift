import SwiftUI
import GitOKCoreKit

struct SpringTheme: GitOKAppChromeTheme {
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

extension SpringTheme {
    static let worktree = SpringTheme(
        identifier: "worktree",
        displayName: "Spring",
        compactName: "Spring",
        description: SpringThemePluginLocalization.string("Fresh spring green theme"),
        iconName: "tree",
        iconColor: Color(hex: "047857"),
        appearanceKind: .light,
        deep: Color(hex: "F5F7F4"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "E6ECE6"),
        primary: Color(hex: "047857"),
        secondary: Color(hex: "2563EB"),
        tertiary: Color(hex: "B45309"),
        text: Color(hex: "172019"),
        secondaryText: Color(hex: "4B5B50"),
        tertiaryText: Color(hex: "78857D")
    )
}
