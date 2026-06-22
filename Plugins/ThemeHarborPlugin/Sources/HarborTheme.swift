import SwiftUI
import GitOKCoreKit

struct HarborTheme: GitOKAppChromeTheme {
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

extension HarborTheme {
    static let harbor = HarborTheme(
        identifier: "remote",
        displayName: "Harbor",
        compactName: "Harbor",
        description: HarborThemePluginLocalization.string("Deep blue water theme"),
        iconName: "network",
        iconColor: Color(hex: "38BDF8"),
        appearanceKind: .dark,
        deep: Color(hex: "07121F"),
        medium: Color(hex: "0D1B2A"),
        light: Color(hex: "16324A"),
        primary: Color(hex: "38BDF8"),
        secondary: Color(hex: "818CF8"),
        tertiary: Color(hex: "2DD4BF"),
        text: Color(hex: "F0F9FF"),
        secondaryText: Color(hex: "B8D7EA"),
        tertiaryText: Color(hex: "7B9DB6")
    )
}
