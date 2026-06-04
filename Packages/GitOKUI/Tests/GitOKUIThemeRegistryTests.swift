import SwiftUI
import Testing
@testable import GitOKUI

private struct MockChromeTheme: GitOKAppChromeTheme {
    let identifier: String
    let displayName: String
    let compactName: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isDarkTheme: Bool
    let followsSystemAppearance: Bool

    init(
        id: String,
        name: String = "Mock",
        pluginTint: Color = .purple,
        isDark: Bool = true,
        followsSystem: Bool = false
    ) {
        identifier = id
        displayName = name
        compactName = String(name.prefix(4))
        description = "Mock theme \(id)"
        iconName = "circle.fill"
        iconColor = pluginTint
        isDarkTheme = isDark
        followsSystemAppearance = followsSystem
    }

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (iconColor, iconColor.opacity(0.8), iconColor.opacity(0.6))
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (.black, .gray, .white)
    }

    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (iconColor.opacity(0.1), iconColor.opacity(0.2), iconColor.opacity(0.3))
    }
}

private func contribution(
    pluginOrder: Int,
    themeId: String,
    editorThemeId: String? = nil,
    isDark: Bool = true,
    followsSystem: Bool = false
) -> GitOKUIThemeContribution {
    let editorId = editorThemeId ?? "editor-\(themeId)"
    return GitOKUIThemeContribution(
        sortKey: ThemeSortKey(pluginOrder: pluginOrder, themeId: themeId),
        chromeTheme: MockChromeTheme(
            id: themeId,
            name: themeId.capitalized,
            isDark: isDark,
            followsSystem: followsSystem
        ),
        editorThemeId: editorId
    )
}

struct GitOKUIThemeRegistryTests {
    @Test
    @MainActor
    func replaceAllEmptyThrowsNoThemesRegistered() {
        let registry = GitOKUIThemeRegistry()
        #expect(throws: ThemeError.noThemesRegistered) {
            try registry.replaceAll([])
        }
    }

    @Test
    @MainActor
    func replaceAllDuplicateIdThrows() {
        let registry = GitOKUIThemeRegistry()
        let a = contribution(pluginOrder: 1, themeId: "same")
        let b = contribution(pluginOrder: 2, themeId: "same")
        #expect(throws: ThemeError.duplicateThemeId("same")) {
            try registry.replaceAll([a, b])
        }
    }

    @Test
    @MainActor
    func defaultThemeIsFirstAfterSort() throws {
        let registry = GitOKUIThemeRegistry()
        try registry.replaceAll([
            contribution(pluginOrder: 20, themeId: "zulu"),
            contribution(pluginOrder: 10, themeId: "alpha"),
            contribution(pluginOrder: 10, themeId: "beta"),
        ])
        #expect(try registry.defaultThemeId() == "alpha")
        #expect(registry.selectedThemeId == "alpha")
    }

    @Test
    @MainActor
    func selectUnknownIdThrows() throws {
        let registry = GitOKUIThemeRegistry()
        try registry.replaceAll([contribution(pluginOrder: 1, themeId: "only")])
        #expect(throws: ThemeError.unknownThemeId("missing")) {
            try registry.select(themeId: "missing")
        }
    }

    @Test
    @MainActor
    func selectUpdatesChromeAndUIStore() throws {
        let registry = GitOKUIThemeRegistry()
        try registry.replaceAll([
            contribution(pluginOrder: 1, themeId: "first"),
            contribution(pluginOrder: 2, themeId: "second"),
        ])
        try registry.select(themeId: "second")
        #expect(registry.chromeTheme.identifier == "second")
        #expect(registry.uiTheme.id == "second")
        #expect(ActiveChromeTheme.current.identifier == "second")
        #expect(GitOKUIThemeStore.shared.theme.id == "second")
    }

    @Test
    @MainActor
    func replaceAllDropsInvalidSelectionToDefault() throws {
        let registry = GitOKUIThemeRegistry()
        try registry.replaceAll([
            contribution(pluginOrder: 1, themeId: "a"),
            contribution(pluginOrder: 2, themeId: "b"),
        ])
        try registry.select(themeId: "b")
        try registry.replaceAll([contribution(pluginOrder: 1, themeId: "a")])
        #expect(registry.selectedThemeId == "a")
    }

    @Test
    @MainActor
    func resolvedEditorThemeIdUsesChromeHook() throws {
        struct AdaptiveChrome: GitOKAppChromeTheme {
            let identifier = "adaptive"
            let displayName = "Adaptive"
            let compactName = "Adp"
            let description = ""
            let iconName = "moon"
            let iconColor = Color.blue

            func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
                (.blue, .blue, .blue)
            }

            func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
                (.black, .gray, .white)
            }

            func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
                (.blue, .blue, .blue)
            }

            func resolvedEditorThemeId(defaultEditorThemeId: String, colorScheme: ColorScheme) -> String {
                colorScheme == .dark ? "dark-id" : "light-id"
            }
        }

        let registry = GitOKUIThemeRegistry()
        try registry.replaceAll([
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: 0, themeId: "adaptive"),
                chromeTheme: AdaptiveChrome(),
                editorThemeId: "fallback"
            ),
        ])
        #expect(registry.resolvedEditorThemeId(colorScheme: .dark) == "dark-id")
        #expect(registry.resolvedEditorThemeId(colorScheme: .light) == "light-id")
    }

    @Test
    @MainActor
    func contributionExposesAppearanceKind() {
        let systemTheme = contribution(pluginOrder: 1, themeId: "system", isDark: false, followsSystem: true)
        #expect(systemTheme.appearanceKind == .system)
        #expect(systemTheme.chromeTheme.followsSystemAppearance)

        let darkTheme = contribution(pluginOrder: 2, themeId: "dark", isDark: true)
        #expect(darkTheme.appearanceKind == .dark)
        #expect(darkTheme.chromeTheme.isDarkTheme)
        #expect(!darkTheme.chromeTheme.followsSystemAppearance)

        let lightTheme = contribution(pluginOrder: 3, themeId: "light", isDark: false)
        #expect(lightTheme.appearanceKind == .light)
        #expect(!lightTheme.chromeTheme.isDarkTheme)
        #expect(!lightTheme.chromeTheme.followsSystemAppearance)
    }
}
