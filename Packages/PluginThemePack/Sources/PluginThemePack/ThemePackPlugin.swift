import KernelCore
import KitSuperLog
import os
import ProviderCommand
import ProviderSettingView
import ProviderTheme
import SwiftUI

/// 旧版主题插件集合的复刻包（单一插件批量注册 19 个主题 + 外观设置入口）。
///
/// 复刻自 LumiApp 的 17 个 `Theme*Plugin`（KernelLumi → KernelCore 适配）：
/// 精简内核（SuperPlugin）没有声明式贡献点，因此本插件在
/// `onBoot(kernel:)` 中主动解析 `ThemeProviding` 与 `SettingViewProviding`：
/// - 批量注册 `LegacyThemeCatalog.all`（19 个 `LumiTheme`，id 与旧版一致）；
/// - 注册「外观」设置入口，详情视图列出全部主题供切换。
///
/// 消费方（设置项、主窗口）通过 `ThemeProviding.themes` 读取全部主题
/// （内置 3 个 + 本插件 19 个），订阅主题事件感知切换。
@MainActor
public final class ThemePackPlugin: SuperPlugin, SuperLog {
    nonisolated static let logger = Logger(subsystem: "com.coffic.gitok.plugin.theme-pack", category: "ThemePack")

    public let id = "com.coffic.gitok.plugin.theme-pack"
    public let order = 100
    public let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.theme-pack",
        name: "Theme Pack",
        description: "Registers 19 legacy themes and provides an appearance switcher in settings.",
        category: .design,
        stage: .stable,
        // 与 Lumi 一致：必须启动才能注册「主题」系统菜单与外观设置入口
        // （policy 为 .disabled 的插件会被内核过滤，菜单不会出现）。
        policy: .required
    )

    public init() {}

    public func onBoot(kernel: KernelCoreContainer) throws {
        guard let theme = kernel.resolveProvider((any ThemeProviding).self) else {
            Self.logger.error("\(Self.t)Failed to resolve ThemeProviding from kernel")
            return
        }
        for legacy in LegacyThemeCatalog.all {
            theme.registerTheme(legacy)
        }

        if let commands = kernel.resolveProvider((any CommandProviding).self) {
            commands.registerCommandGroup(Self.makeCommandGroup(theme: theme))
        }

        // 设置入口：外观 / 主题选择（设置视图未注册时优雅降级）。
        if let settings = kernel.resolveProvider((any SettingViewProviding).self) {
            settings.addEntries([
                SettingEntryItem(
                    id: "appearance",
                    title: LumiPluginLocalization.string("Appearance", bundle: .module),
                    systemImage: "paintpalette",
                    order: 2
                ) {
                    ThemeSettingsDetailView(theme: theme)
                },
            ])
        }
    }

    public func onShutdown(kernel: KernelCoreContainer) throws {
        kernel.resolveProvider((any CommandProviding).self)?
            .unregisterCommandGroup(id: Self.commandGroupID)
        if let theme = kernel.resolveProvider((any ThemeProviding).self) {
            for legacy in LegacyThemeCatalog.all {
                theme.unregisterTheme(id: legacy.id)
            }
        }
        kernel.resolveProvider((any SettingViewProviding).self)?
            .removeEntries(ids: ["appearance"])
    }

    private static let commandGroupID = "com.coffic.lumi.theme.menu"

    static func localizedMenuName(locale: Locale = .current) -> String {
        LumiPluginLocalization.string("Theme", bundle: .module, locale: locale)
    }

    private static func makeCommandGroup(theme: any ThemeProviding) -> CommandMenuGroup {
        CommandMenuGroup(
            id: commandGroupID,
            name: localizedMenuName(),
            items: theme.themes.map { item in
                CommandItem(
                    id: "\(commandGroupID).select.\(item.id)",
                    title: item.displayName,
                    stateProvider: {
                        theme.selectedThemeId == item.id ? .on : .off
                    }
                ) {
                    try? theme.selectTheme(id: item.id)
                }
            },
            placement: .topLevelMenu
        )
    }
}
