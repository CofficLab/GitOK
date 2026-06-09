import SwiftUI
import GitOKCoreKit

struct EmberTheme: GitOKAppChromeTheme {
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

extension EmberTheme {
    static let conflict = EmberTheme(
        identifier: "conflict",
        displayName: "Ember",
        compactName: "Ember",
        description: "Warm dark theme with orange, red, and gold contrast",
        iconName: "exclamationmark.triangle",
        iconColor: Color(hex: "F97316"),
        appearanceKind: .dark,
        deep: Color(hex: "17120F"),
        medium: Color(hex: "221A16"),
        light: Color(hex: "31231C"),
        primary: Color(hex: "F97316"),
        secondary: Color(hex: "EF4444"),
        tertiary: Color(hex: "FACC15"),
        text: Color(hex: "FFF7ED"),
        secondaryText: Color(hex: "FED7AA"),
        tertiaryText: Color(hex: "C69A74")
    )
}
