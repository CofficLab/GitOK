import Foundation
import KernelCore

/// 插件管理页用到的文案常量集中管理。
///
/// 与新版本其它插件包（PluginSettingGeneral / PluginThemePack）一致，
/// 通过 `LumiPluginLocalization` 走运行时本地化（`Resources/Localizable.xcstrings`）。
enum PluginPluginManagerText {
    static let plugins = pluginLocalization.string("Plugin Management")
    static let pluginsHint = pluginLocalization.string("Manage all registered plugins")
    static let aboutDescription = pluginLocalization.string("List and display all registered plugins.")
    static let searchPlugins = pluginLocalization.string("Search Plugins")
    static let noPluginsFound = pluginLocalization.string("No Plugins Found")
    static let selectPlugin = pluginLocalization.string("Select a Plugin")
    static let pluginsCount = pluginLocalization.string("%lld Plugins")
    static let enabledCount = pluginLocalization.string("%lld Enabled")
    static let allCategories = pluginLocalization.string("All")
    static let alwaysOn = pluginLocalization.string("Always On")
    static let disabled = pluginLocalization.string("Disabled")
    static let disabledPermanently = pluginLocalization.string("Deactivated")
    static let enabled = pluginLocalization.string("Enabled")
    static let noDetailsProvided = pluginLocalization.string("No Details Available")
    static let noDetailsHint = pluginLocalization.string("The plugin author did not provide a detail view.")
    static let enable = pluginLocalization.string("Enable")

    // 详情面板信息区
    static let categoryLabel = pluginLocalization.string("Category")
    static let versionLabel = pluginLocalization.string("Version")
    static let policyLabel = pluginLocalization.string("Policy")
    static let identifierLabel = pluginLocalization.string("Identifier")
    static let permissionsTitle = pluginLocalization.string("Permissions")

    // 关于视图
    static let browsePlugins = pluginLocalization.string("Browse Useful Plugins")
    static let coreCapabilities = pluginLocalization.string("Core Capabilities")
    static let whereToFindIt = pluginLocalization.string("Where to Find It")
    static let settingsEntry = pluginLocalization.string("Settings → Plugin Management")
    static let capabilityCatalogTitle = pluginLocalization.string("Plugin Catalog")
    static let capabilityCatalogDescription = pluginLocalization.string("View all registered plugins at a glance.")
    static let capabilitySearchTitle = pluginLocalization.string("Search")
    static let capabilitySearchDescription = pluginLocalization.string("Find plugins instantly by name.")
    static let capabilityFilterTitle = pluginLocalization.string("Category Filter")
    static let capabilityFilterDescription = pluginLocalization.string("Filter by plugin category.")
    static let capabilityDetailTitle = pluginLocalization.string("Plugin Details")
    static let capabilityDetailDescription = pluginLocalization.string("View each plugin's description and stage.")
    static let capabilityOrderTitle = pluginLocalization.string("Ordering")
    static let capabilityOrderDescription = pluginLocalization.string("Plugins are shown in registration order.")
}

// MARK: - 新版枚举的展示映射（对齐旧版 LumiPluginCategory / Stage / Policy 语义）

// `PluginEnablePolicy.isConfigurable` 由 KernelCore 提供（对齐旧版 `LumiPluginPolicy.isConfigurable`），
// 此处不再重复声明。

extension PluginCategory {
    /// 展示顺序（用于分类筛选标签栏；`allCases` 缺失时作为排序依据）。
    static var displayOrder: [PluginCategory] {
        [
            .core, .chat, .llm, .system, .project, .feature, .editor,
            .integration, .design, .general,
        ]
    }

    var displayName: String {
        switch self {
        case .core: pluginLocalization.string("Core")
        case .chat: pluginLocalization.string("Chat")
        case .llm: pluginLocalization.string("Model")
        case .editor: pluginLocalization.string("Editor")
        case .project: pluginLocalization.string("Project")
        case .feature: pluginLocalization.string("Feature")
        case .system: pluginLocalization.string("System")
        case .design: pluginLocalization.string("Design")
        case .integration: pluginLocalization.string("Integration")
        case .general: pluginLocalization.string("General")
        }
    }

    var systemImage: String {
        switch self {
        case .core: "cube"
        case .chat: "bubble.left.and.bubble.right"
        case .llm: "cpu"
        case .editor: "chevron.left.forwardslash.chevron.right"
        case .project: "folder"
        case .feature: "square.grid.2x2"
        case .system: "desktopcomputer"
        case .design: "paintbrush"
        case .integration: "arrow.up.right.square"
        case .general: "puzzlepiece.extension"
        }
    }

    var sortOrder: Int {
        switch self {
        case .core: 10
        case .chat: 15
        case .llm: 20
        case .system: 25
        case .project: 30
        case .feature: 32
        case .editor: 35
        case .integration: 40
        case .design: 45
        case .general: 50
        }
    }
}

extension PluginStage {
    var displayName: String {
        switch self {
        case .experimental: pluginLocalization.string("Experimental")
        case .preview: pluginLocalization.string("Preview")
        case .stable: pluginLocalization.string("Stable")
        case .deprecated: pluginLocalization.string("Deprecated")
        }
    }
}
