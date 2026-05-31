import GitOKUI
import SwiftUI

struct RiverTheme: GitOKAppChromeTheme {
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

extension RiverTheme {
    static let branchFlow = RiverTheme(
        identifier: "branch-flow",
        displayName: "River",
        compactName: "River",
        description: "Flowing dark teal theme with blue and fresh green accents",
        iconName: "arrow.triangle.branch",
        iconColor: Color(hex: "2DD4BF"),
        isDarkTheme: true,
        followsSystemAppearance: false,
        deep: Color(hex: "061414"),
        medium: Color(hex: "0B1F1D"),
        light: Color(hex: "14302D"),
        primary: Color(hex: "2DD4BF"),
        secondary: Color(hex: "38BDF8"),
        tertiary: Color(hex: "84CC16"),
        text: Color(hex: "F0FDFA"),
        secondaryText: Color(hex: "B7DCD6"),
        tertiaryText: Color(hex: "789995")
    )
}
