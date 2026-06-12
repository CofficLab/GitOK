import SwiftUI

// MARK: - App Chrome Theme

/// IDE / 应用外壳主题协议（工作区、侧栏、全局背景等）。
/// 插件主题实现此协议；组件库语义色见 ``GitOKUITheme``。
///
/// ## 明暗模式支持
/// 主题可以通过 `appearanceKind` 属性指定其明暗模式行为：
/// - `.dark`: 仅支持暗色模式
/// - `.light`: 仅支持亮色模式
/// - `.system`: 自动适配系统明暗模式
///
/// 对于支持 `.system` 的主题，需使用 `Color.adaptive(light:dark:)` 为不同模式提供不同的颜色值。
public protocol GitOKAppChromeTheme {
    var identifier: String { get }
    var displayName: String { get }
    var compactName: String { get }
    var description: String { get }
    var iconName: String { get }
    var iconColor: Color { get }
    var appearanceKind: ThemeAppearanceKind { get }

    func resolvedEditorThemeId(defaultEditorThemeId: String, colorScheme: ColorScheme) -> String

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color)
    func atmosphereColors() -> (deep: Color, medium: Color, light: Color)
    func glowColors() -> (subtle: Color, medium: Color, intense: Color)

    func backgroundGradient() -> LinearGradient
    func glowGradient() -> RadialGradient
    func borderGradient() -> LinearGradient

    func workspaceBackgroundColor() -> Color
    func sidebarBackgroundColor() -> Color
    func sidebarSelectionColor() -> Color
    func sidebarSelectionTextColor() -> Color
    func workspaceTextColor() -> Color
    func workspaceSecondaryTextColor() -> Color
    func workspaceTertiaryTextColor() -> Color

    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView
}

// MARK: - Default Implementations

public extension GitOKAppChromeTheme {
    var appearanceKind: ThemeAppearanceKind { .dark }

    func resolvedEditorThemeId(defaultEditorThemeId: String, colorScheme: ColorScheme) -> String {
        defaultEditorThemeId
    }

    func workspaceBackgroundColor() -> Color {
        atmosphereColors().medium
    }

    func sidebarBackgroundColor() -> Color {
        atmosphereColors().deep
    }

    func sidebarSelectionColor() -> Color {
        accentColors().primary.opacity(0.22)
    }

    func sidebarSelectionTextColor() -> Color {
        Color.white
    }

    func workspaceTextColor() -> Color {
        Color.adaptive(light: "1C1C1E", dark: "FFFFFF")
    }

    func workspaceSecondaryTextColor() -> Color {
        Color.adaptive(light: "6B6B7B", dark: "EBEBF5")
    }

    func workspaceTertiaryTextColor() -> Color {
        Color.adaptive(light: "98989E", dark: "98989E")
    }

    func backgroundGradient() -> LinearGradient {
        let colors = atmosphereColors()
        return LinearGradient(
            colors: [colors.deep, colors.medium, colors.light, colors.medium, colors.deep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func glowGradient() -> RadialGradient {
        let colors = glowColors()
        return RadialGradient(
            colors: [colors.intense, colors.medium, colors.subtle, Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 250
        )
    }

    func borderGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.15), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func makeGlobalBackground(proxy: GeometryProxy) -> AnyView {
        AnyView(
            ZStack {
                Circle()
                    .fill(glowGradient())
                    .frame(width: 600, height: 600)
                    .blur(radius: 120)
                    .offset(x: -200, y: -200)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowColors().intense, glowColors().medium, Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .position(x: proxy.size.width, y: proxy.size.height)
            }
        )
    }
}
