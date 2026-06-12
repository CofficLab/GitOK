import SwiftUI
import GitOKCoreKit

struct OrchardTheme: GitOKAppChromeTheme {
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

extension OrchardTheme {
    static let orchard = OrchardTheme(
        identifier: "stash",
        displayName: "Orchard",
        compactName: "Orchard",
        description: "Earthy dark theme with amber, blue, and lime accents",
        iconName: "tray.full",
        iconColor: Color(hex: "FBBF24"),
        appearanceKind: .dark,
        deep: Color(hex: "15130B"),
        medium: Color(hex: "211D12"),
        light: Color(hex: "332B17"),
        primary: Color(hex: "FBBF24"),
        secondary: Color(hex: "60A5FA"),
        tertiary: Color(hex: "A3E635"),
        text: Color(hex: "FFFBEA"),
        secondaryText: Color(hex: "E8D9A6"),
        tertiaryText: Color(hex: "A99B70")
    )
}
