import SwiftUI
import GitOKCoreKit

struct MountainTheme: GitOKAppChromeTheme {
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

extension MountainTheme {
    static let mountain = MountainTheme(
        identifier: "archive",
        displayName: "Mountain",
        compactName: "Mountain",
        description: MountainThemePluginLocalization.string("Quiet stone light theme"),
        iconName: "archivebox",
        iconColor: Color(hex: "64748B"),
        appearanceKind: .light,
        deep: Color(hex: "F1F5F9"),
        medium: Color(hex: "FFFFFF"),
        light: Color(hex: "E2E8F0"),
        primary: Color(hex: "475569"),
        secondary: Color(hex: "0F766E"),
        tertiary: Color(hex: "7C2D12"),
        text: Color(hex: "172033"),
        secondaryText: Color(hex: "4B5565"),
        tertiaryText: Color(hex: "7B8494")
    )
}
