import SwiftUI
import GitOKCoreKit

struct HarborTheme: GitOKAppChromeTheme {
    let identifier: String
    let displayName: String
    let compactName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isDarkTheme: Bool
    let followsSystemAppearance: Bool
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
            subtle: primary.opacity(isDarkTheme ? 0.12 : 0.08),
            medium: secondary.opacity(isDarkTheme ? 0.16 : 0.10),
            intense: tertiary.opacity(isDarkTheme ? 0.18 : 0.12)
        )
    }
    func workspaceBackgroundColor() -> Color { medium }
    func sidebarBackgroundColor() -> Color { deep }
    func sidebarSelectionColor() -> Color { primary.opacity(isDarkTheme ? 0.24 : 0.14) }
    func sidebarSelectionTextColor() -> Color { isDarkTheme ? .white : Color(hex: "111827") }
    func workspaceTextColor() -> Color { text }
    func workspaceSecondaryTextColor() -> Color { secondaryText }
    func workspaceTertiaryTextColor() -> Color { tertiaryText }
    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView {
        AnyView(
            ZStack {
                backgroundGradient()
                VStack(spacing: 0) {
                    Rectangle().fill(primary.opacity(isDarkTheme ? 0.10 : 0.05)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(secondary.opacity(isDarkTheme ? 0.08 : 0.04)).frame(height: 1)
                }
                .padding(.horizontal, 24)
                HStack(spacing: 0) {
                    Rectangle().fill(primary.opacity(isDarkTheme ? 0.08 : 0.04)).frame(width: 1)
                    Spacer()
                    Rectangle().fill(tertiary.opacity(isDarkTheme ? 0.06 : 0.035)).frame(width: 1)
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
        description: "Deep blue theme with clear water tones and teal highlights",
        iconName: "network",
        iconColor: Color(hex: "38BDF8"),
        isDarkTheme: true,
        followsSystemAppearance: false,
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
