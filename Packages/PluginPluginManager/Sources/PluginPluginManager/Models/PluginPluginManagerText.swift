import Foundation
import KernelCore

/// 插件管理页用到的文案常量集中管理。
///
/// 与新版本其它插件包（PluginSettingGeneral / PluginThemePack）一致，
/// 通过 `LumiPluginLocalization` 走运行时本地化（`Resources/Localizable.xcstrings`）。
enum PluginPluginManagerText {
    static let plugins = LumiPluginLocalization.string("Plugin Management", bundle: .module)
    static let pluginsHint = LumiPluginLocalization.string("Manage all registered plugins", bundle: .module)
    static let aboutDescription = LumiPluginLocalization.string("List and display all registered plugins.", bundle: .module)
    static let searchPlugins = LumiPluginLocalization.string("Search Plugins", bundle: .module)
    static let noPluginsFound = LumiPluginLocalization.string("No Plugins Found", bundle: .module)
    static let selectPlugin = LumiPluginLocalization.string("Select a Plugin", bundle: .module)
    static let pluginsCount = LumiPluginLocalization.string("%lld Plugins", bundle: .module)
    static let enabledCount = LumiPluginLocalization.string("%lld Enabled", bundle: .module)
    static let allCategories = LumiPluginLocalization.string("All", bundle: .module)
    static let alwaysOn = LumiPluginLocalization.string("Always On", bundle: .module)
    static let disabled = LumiPluginLocalization.string("Disabled", bundle: .module)
    static let disabledPermanently = LumiPluginLocalization.string("Deactivated", bundle: .module)
    static let enabled = LumiPluginLocalization.string("Enabled", bundle: .module)
    static let noDetailsProvided = LumiPluginLocalization.string("No Details Available", bundle: .module)
    static let noDetailsHint = LumiPluginLocalization.string("The plugin author did not provide a detail view.", bundle: .module)
    static let enable = LumiPluginLocalization.string("Enable", bundle: .module)

    // 详情面板信息区
    static let categoryLabel = LumiPluginLocalization.string("Category", bundle: .module)
    static let versionLabel = LumiPluginLocalization.string("Version", bundle: .module)
    static let policyLabel = LumiPluginLocalization.string("Policy", bundle: .module)
    static let identifierLabel = LumiPluginLocalization.string("Identifier", bundle: .module)
    static let permissionsTitle = LumiPluginLocalization.string("Permissions", bundle: .module)

    // 关于视图
    static let browsePlugins = LumiPluginLocalization.string("Browse Useful Plugins", bundle: .module)
    static let coreCapabilities = LumiPluginLocalization.string("Core Capabilities", bundle: .module)
    static let whereToFindIt = LumiPluginLocalization.string("Where to Find It", bundle: .module)
    static let settingsEntry = LumiPluginLocalization.string("Settings → Plugin Management", bundle: .module)
    static let capabilityCatalogTitle = LumiPluginLocalization.string("Plugin Catalog", bundle: .module)
    static let capabilityCatalogDescription = LumiPluginLocalization.string("View all registered plugins at a glance.", bundle: .module)
    static let capabilitySearchTitle = LumiPluginLocalization.string("Search", bundle: .module)
    static let capabilitySearchDescription = LumiPluginLocalization.string("Find plugins instantly by name.", bundle: .module)
    static let capabilityFilterTitle = LumiPluginLocalization.string("Category Filter", bundle: .module)
    static let capabilityFilterDescription = LumiPluginLocalization.string("Filter by plugin category.", bundle: .module)
    static let capabilityDetailTitle = LumiPluginLocalization.string("Plugin Details", bundle: .module)
    static let capabilityDetailDescription = LumiPluginLocalization.string("View each plugin's description and stage.", bundle: .module)
    static let capabilityOrderTitle = LumiPluginLocalization.string("Ordering", bundle: .module)
    static let capabilityOrderDescription = LumiPluginLocalization.string("Plugins are shown in registration order.", bundle: .module)
}

// MARK: - 新版枚举的展示映射（对齐旧版 LumiPluginCategory / Stage / Policy 语义）

// `PluginEnablePolicy.isConfigurable` 由 KernelCore 提供（对齐旧版 `LumiPluginPolicy.isConfigurable`），
// 此处不再重复声明。

extension PluginCategory {
    /// 展示顺序（用于分类筛选标签栏；`allCases` 缺失时作为排序依据）。
    static var displayOrder: [PluginCategory] {
        [
            .core, .chat, .llm, .system, .project, .editor,
            .integration, .design, .general,
        ]
    }

    var displayName: String {
        switch self {
        case .core: LumiPluginLocalization.string("Core", bundle: .module)
        case .chat: LumiPluginLocalization.string("Chat", bundle: .module)
        case .llm: LumiPluginLocalization.string("Model", bundle: .module)
        case .editor: LumiPluginLocalization.string("Editor", bundle: .module)
        case .project: LumiPluginLocalization.string("Project", bundle: .module)
        case .system: LumiPluginLocalization.string("System", bundle: .module)
        case .design: LumiPluginLocalization.string("Design", bundle: .module)
        case .integration: LumiPluginLocalization.string("Integration", bundle: .module)
        case .general: LumiPluginLocalization.string("General", bundle: .module)
        }
    }

    var systemImage: String {
        switch self {
        case .core: "cube"
        case .chat: "bubble.left.and.bubble.right"
        case .llm: "cpu"
        case .editor: "chevron.left.forwardslash.chevron.right"
        case .project: "folder"
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
        case .experimental: LumiPluginLocalization.string("Experimental", bundle: .module)
        case .preview: LumiPluginLocalization.string("Preview", bundle: .module)
        case .stable: LumiPluginLocalization.string("Stable", bundle: .module)
        case .deprecated: LumiPluginLocalization.string("Deprecated", bundle: .module)
        }
    }
}
