import GitOKCoreKit

public struct MidnightThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeMidnightPlugin",
        displayName: "Midnight Theme",
        description: "Quiet terminal-green dark theme",
        iconName: "terminal",
        order: 123,
        policy: .disabled,
        tableName: "ThemeMidnight"
    )

    public static let shared = MidnightThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: MidnightTheme.terminal.identifier),
                chromeTheme: MidnightTheme.terminal,
                editorThemeId: MidnightTheme.terminal.identifier
            ),
        ]
    }
}
