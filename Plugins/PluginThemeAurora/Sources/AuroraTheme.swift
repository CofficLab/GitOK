import SwiftUI
import GitOKCoreKit

struct AuroraTheme: GitOKAppChromeTheme {
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

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (primary, secondary, tertiary)
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (deep, medium, light)
    }

    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            subtle: primary.opacity(isDarkTheme ? 0.12 : 0.08),
            medium: secondary.opacity(isDarkTheme ? 0.16 : 0.10),
            intense: tertiary.opacity(isDarkTheme ? 0.18 : 0.12)
        )
    }

    func workspaceBackgroundColor() -> Color {
        medium
    }

    func sidebarBackgroundColor() -> Color {
        deep
    }

    func sidebarSelectionColor() -> Color {
        primary.opacity(isDarkTheme ? 0.24 : 0.14)
    }

    func sidebarSelectionTextColor() -> Color {
        isDarkTheme ? .white : Color(hex: "111827")
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
                        .fill(primary.opacity(isDarkTheme ? 0.10 : 0.05))
                        .frame(height: 1)
                    Spacer()
                    Rectangle()
                        .fill(secondary.opacity(isDarkTheme ? 0.08 : 0.04))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(isDarkTheme ? 0.08 : 0.04))
                        .frame(width: 1)
                    Spacer()
                    Rectangle()
                        .fill(tertiary.opacity(isDarkTheme ? 0.06 : 0.035))
                        .frame(width: 1)
                }
                .padding(.vertical, 20)
            }
        )
    }
}

extension AuroraTheme {
    static let commitGraph = AuroraTheme(
        identifier: "commit-graph",
        displayName: "Aurora",
        compactName: "Aurora",
        description: "Deep cyan night theme with bright green and amber highlights",
        iconName: "point.3.connected.trianglepath.dotted",
        iconColor: Color(hex: "22D3EE"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "071118"),
        medium: Color(hex: "0E1B24"),
        light: Color(hex: "162A36"),
        primary: Color(hex: "22D3EE"),
        secondary: Color(hex: "A3E635"),
        tertiary: Color(hex: "F59E0B"),
        text: Color(hex: "ECFEFF"),
        secondaryText: Color(hex: "B6D7DF"),
        tertiaryText: Color(hex: "7FA6B1")
    )
}
