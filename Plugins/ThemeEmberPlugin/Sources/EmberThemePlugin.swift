import GitOKCoreKit

public struct EmberThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeEmberPlugin",
        displayName: "Ember Theme",
        description: "Warm orange dark theme",
        iconName: "exclamationmark.triangle",
        order: 124,
        policy: .disabled,
        tableName: "Localizable"
    )

    public static let shared = EmberThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: EmberTheme.conflict.identifier),
                chromeTheme: EmberTheme.conflict,
                editorThemeId: EmberTheme.conflict.identifier
            ),
        ]
    }
}
