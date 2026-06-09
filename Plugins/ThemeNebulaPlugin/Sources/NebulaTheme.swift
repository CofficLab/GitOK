import SwiftUI
import GitOKCoreKit

struct NebulaTheme: GitOKAppChromeTheme {
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

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) { (primary, secondary, tertiary) }
    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) { (deep, medium, light) }
    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            subtle: primary.opacity(0.12),
            medium: secondary.opacity(0.16),
            intense: tertiary.opacity(0.18)
        )
    }
    func workspaceBackgroundColor() -> Color { medium }
    func sidebarBackgroundColor() -> Color { deep }
    func sidebarSelectionColor() -> Color { primary.opacity(0.24) }
    func sidebarSelectionTextColor() -> Color { .white }
    func workspaceTextColor() -> Color { text }
    func workspaceSecondaryTextColor() -> Color { secondaryText }
    func workspaceTertiaryTextColor() -> Color { tertiaryText }
    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView {
        AnyView(
            ZStack {
                backgroundGradient()
                VStack(spacing: 0) {
                    Rectangle().fill(primary.opacity(0.10)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(secondary.opacity(0.08)).frame(height: 1)
                }
                .padding(.horizontal, 24)
                HStack(spacing: 0) {
                    Rectangle().fill(primary.opacity(0.08)).frame(width: 1)
                    Spacer()
                    Rectangle().fill(tertiary.opacity(0.06)).frame(width: 1)
                }
                .padding(.vertical, 20)
            }
        )
    }
}

extension NebulaTheme {
    static let nebula = NebulaTheme(
        identifier: "pull-request",
        displayName: "Nebula",
        compactName: "Nebula",
        description: "Violet dark theme with cyan and pink atmospheric accents",
        iconName: "arrow.triangle.pull",
        iconColor: Color(hex: "A78BFA"),
        appearanceKind: .dark,
        deep: Color(hex: "120F1C"),
        medium: Color(hex: "1B1728"),
        light: Color(hex: "29223A"),
        primary: Color(hex: "A78BFA"),
        secondary: Color(hex: "22D3EE"),
        tertiary: Color(hex: "F472B6"),
        text: Color(hex: "F7F2FF"),
        secondaryText: Color(hex: "D8CFF0"),
        tertiaryText: Color(hex: "9E91BC")
    )
}
