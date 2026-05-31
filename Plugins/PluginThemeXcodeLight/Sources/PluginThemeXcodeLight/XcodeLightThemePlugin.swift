import GitOKCoreKit
import GitOKUI

public struct XcodeLightThemePlugin: GitOKPackagedPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeXcodeLightPlugin",
        displayName: "Xcode Light Theme",
        description: "Xcode-inspired light theme",
        iconName: "hammer",
        order: 137,
        allowUserToggle: false,
        defaultEnabled: true,
        tableName: "ThemeXcodeLight"
    )

    public static let shared = XcodeLightThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: XcodeLightTheme.xcodeLight.identifier),
                chromeTheme: XcodeLightTheme.xcodeLight,
                editorThemeId: XcodeLightTheme.xcodeLight.identifier
            ),
        ]
    }
}

