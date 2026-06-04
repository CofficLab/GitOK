import Combine
import GitOKUI
import SwiftUI

@MainActor
final class AppThemeVM: ObservableObject {
    private let registry: GitOKUIThemeRegistry
    private let pluginProvider: PluginVM
    private let settings: AppAppearanceSettingsStore
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var themes: [GitOKUIThemeContribution] = []

    @Published var currentThemeId: String {
        didSet {
            guard oldValue != currentThemeId else { return }
            applySelection(themeId: currentThemeId, shouldPersist: true)
        }
    }

    init(
        pluginProvider: PluginVM,
        registry: GitOKUIThemeRegistry? = nil,
        settings: AppAppearanceSettingsStore = .shared
    ) {
        let registry = registry ?? .shared
        self.pluginProvider = pluginProvider
        self.registry = registry
        self.settings = settings

        Self.sync(pluginProvider: pluginProvider, registry: registry)
        let availableThemes = registry.themes
        let initialId = Self.initialThemeId(
            savedId: settings.selectedThemeId,
            themes: availableThemes,
            fallbackId: registry.selectedThemeId
        )

        self.themes = availableThemes
        self.currentThemeId = initialId
        applySelection(themeId: initialId, shouldPersist: false)

        if pluginProvider.hasPlugins {
            pluginProvider.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.reloadThemes()
                }
                .store(in: &cancellables)
        }
    }

    var currentTheme: GitOKUIThemeContribution? {
        themes.first(where: { $0.id == currentThemeId }) ?? themes.first
    }

    var activeChromeTheme: any GitOKAppChromeTheme {
        guard let theme = currentTheme else {
            return GitOKDefaultChromeTheme()
        }
        return theme.chromeTheme
    }

    var accentColor: Color {
        activeChromeTheme.accentColors().primary
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            switch activeChromeTheme.appearanceKind {
            case .dark:
                return .dark
            case .light:
                return .light
            case .system:
                return nil
            }
        }
    }

    func selectTheme(_ themeId: String) {
        guard themes.contains(where: { $0.id == themeId }) else { return }
        if currentThemeId == themeId {
            settings.selectedThemeId = themeId
            refreshAppearance()
        } else {
            currentThemeId = themeId
        }
    }

    func reloadThemes() {
        Self.sync(pluginProvider: pluginProvider, registry: registry)
        themes = registry.themes
        let nextId = Self.initialThemeId(
            savedId: settings.selectedThemeId ?? currentThemeId,
            themes: themes,
            fallbackId: registry.selectedThemeId
        )
        if currentThemeId != nextId {
            currentThemeId = nextId
        } else {
            applySelection(themeId: nextId, shouldPersist: false)
            refreshAppearance()
        }
    }

    func refreshAppearance() {
        objectWillChange.send()
    }

    private func applySelection(themeId: String, shouldPersist: Bool) {
        do {
            try registry.select(themeId: themeId)
            if shouldPersist {
                settings.selectedThemeId = themeId
            }
        } catch {
            guard let fallbackId = registry.selectedThemeId else { return }
            if currentThemeId != fallbackId {
                currentThemeId = fallbackId
            }
        }
    }

    private static func sync(pluginProvider: PluginVM, registry: GitOKUIThemeRegistry) {
        guard pluginProvider.hasPlugins else {
            do {
                try registry.replaceAll([defaultThemeContribution()])
            } catch {
                assertionFailure("Failed to register default theme: \(error)")
            }
            return
        }

        let contributions = pluginProvider.getThemeContributions()
        do {
            try registry.replaceAll(contributions)
        } catch {
            do {
                try registry.replaceAll([defaultThemeContribution()])
            } catch {
                assertionFailure("Failed to register fallback theme: \(error)")
            }
        }
    }

    private static func defaultThemeContribution() -> GitOKUIThemeContribution {
        GitOKUIThemeContribution(
            sortKey: ThemeSortKey(pluginOrder: 0, themeId: GitOKDefaultChromeTheme().identifier),
            chromeTheme: GitOKDefaultChromeTheme(),
            editorThemeId: "gitok-default"
        )
    }

    private static func initialThemeId(
        savedId: String?,
        themes: [GitOKUIThemeContribution],
        fallbackId: String?
    ) -> String {
        if let savedId, themes.contains(where: { $0.id == savedId }) {
            return savedId
        }
        return fallbackId ?? themes.first?.id ?? GitOKDefaultChromeTheme().identifier
    }
}

struct GitOKDefaultChromeTheme: GitOKAppChromeTheme {
    let identifier = "gitok-default"
    let displayName = "GitOK"
    let compactName = "GitOK"
    let description = "Balanced GitOK default theme"
    let iconName = "app.badge"
    let iconColor = Color.adaptive(light: "2563EB", dark: "60A5FA")
    let followsSystemAppearance = true

    func accentColors() -> (primary: Color, secondary: Color, tertiary: Color) {
        (
            primary: Color.adaptive(light: "2563EB", dark: "60A5FA"),
            secondary: Color.adaptive(light: "16A34A", dark: "22C55E"),
            tertiary: Color.adaptive(light: "7C3AED", dark: "A78BFA")
        )
    }

    func atmosphereColors() -> (deep: Color, medium: Color, light: Color) {
        (
            deep: Color.adaptive(light: "F6F8FA", dark: "0D1117"),
            medium: Color.adaptive(light: "FFFFFF", dark: "161B22"),
            light: Color.adaptive(light: "E5E7EB", dark: "21262D")
        )
    }

    func glowColors() -> (subtle: Color, medium: Color, intense: Color) {
        (
            subtle: accentColors().primary.opacity(0.10),
            medium: accentColors().primary.opacity(0.18),
            intense: accentColors().secondary.opacity(0.24)
        )
    }

    func workspaceBackgroundColor() -> Color {
        atmosphereColors().medium
    }

    func sidebarBackgroundColor() -> Color {
        atmosphereColors().deep
    }
}
