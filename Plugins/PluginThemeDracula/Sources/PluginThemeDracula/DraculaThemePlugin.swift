import GitOKCoreKit
import GitOKUI

public struct DraculaThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeDraculaPlugin",
        displayName: "Dracula Theme",
        description: "Classic vivid dark theme",
        iconName: "moon.stars",
        order: 135,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeDracula"
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

