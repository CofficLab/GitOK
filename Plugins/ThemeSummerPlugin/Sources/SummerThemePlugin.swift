import GitOKCoreKit

public struct SummerThemePlugin: GitOKPlugin {
    public static let metadata = GitOKPluginMetadata(
        id: "ThemeSummerPlugin",
        displayName: "Summer Theme",
        description: "Warm golden light theme",
        iconName: "tag",
        order: 130,
        policy: .disabled,
        tableName: "Localizable"
    )

    public static let shared = SummerThemePlugin()

    private init() {}

    @MainActor
    public func themeContributions() -> [GitOKUIThemeContribution] {
        [
            GitOKUIThemeContribution(
                sortKey: ThemeSortKey(pluginOrder: Self.metadata.order, themeId: SummerTheme.release.identifier),
                chromeTheme: SummerTheme.release,
                editorThemeId: SummerTheme.release.identifier
            ),
        ]
    }
}

