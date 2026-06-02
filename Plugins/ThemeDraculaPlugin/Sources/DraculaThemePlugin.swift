import GitOKCoreKit

public struct DraculaThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeDraculaPlugin",
        displayName: "Dracula Theme",
        description: "Classic vivid dark theme",
        iconName: "moon.stars",
        order: 135,
        policy: .disabled,
        tableName: "Localizable"
    )

    public static let shared = DraculaThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: DraculaTheme.dracula.identifier),
                chromeTheme: DraculaTheme.dracula,
                editorThemeId: DraculaTheme.dracula.identifier
            ),
        ]
    }
}

