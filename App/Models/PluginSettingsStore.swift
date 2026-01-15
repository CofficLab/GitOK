import Foundation

/// 插件设置存储：管理插件的启用/禁用状态
class PluginSettingsStore {
    static let shared = PluginSettingsStore()

    private let userDefaultsKey = "GitOK_PluginSettings"

    private init() {}

    /// 获取插件的启用状态
    /// - Parameter pluginId: 插件ID
    /// - Returns: true 表示启用，false 表示禁用
    func isPluginEnabled(_ pluginId: String) -> Bool {
        let settings = loadSettings()
        // 如果没有设置，默认启用
        return settings[pluginId] ?? true
    }

    /// 设置插件的启用状态
    /// - Parameters:
    ///   - pluginId: 插件ID
    ///   - enabled: true 表示启用，false 表示禁用
    func setPluginEnabled(_ pluginId: String, enabled: Bool) {
        var settings = loadSettings()
        settings[pluginId] = enabled
        saveSettings(settings)
    }

    /// 加载所有插件设置
    private func loadSettings() -> [String: Bool] {
        UserDefaults.standard.object(forKey: userDefaultsKey) as? [String: Bool] ?? [:]
    }

    /// 保存插件设置
    private func saveSettings(_ settings: [String: Bool]) {
        UserDefaults.standard.set(settings, forKey: userDefaultsKey)
    }
}

/// 插件信息模型
struct PluginInfo: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    /// 插件是否开发者启用（检查插件的 static let enable 属性）
    let isDeveloperEnabled: () -> Bool

    init(id: String, name: String, description: String, icon: String = "puzzlepiece.extension", isDeveloperEnabled: @escaping () -> Bool = { true }) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.isDeveloperEnabled = isDeveloperEnabled
    }
}

/// 可配置的插件列表
enum ConfigurablePlugins {
    /// 所有可配置的插件（仅包含开发者启用的插件）
    static var allPlugins: [PluginInfo] {
        [
            // Open 系列插件
            PluginInfo(
                id: "OpenXcode",
                name: "OpenXcode",
                description: "在 Xcode 中打开当前项目",
                icon: "hammer",
                isDeveloperEnabled: { OpenXcodePlugin.enable }
            ),
            PluginInfo(
                id: "OpenVSCode",
                name: "OpenVSCode",
                description: "在 VS Code 中打开当前项目",
                icon: "code",
                isDeveloperEnabled: { OpenVSCodePlugin.enable }
            ),
            PluginInfo(
                id: "OpenTrae",
                name: "OpenTrae",
                description: "在 Trae 中打开当前项目",
                icon: "brain",
                isDeveloperEnabled: { OpenTraePlugin.enable }
            ),
            PluginInfo(
                id: "OpenFinder",
                name: "OpenFinder",
                description: "在 Finder 中打开当前项目目录",
                icon: "folder",
                isDeveloperEnabled: { OpenFinderPlugin.enable }
            ),
            PluginInfo(
                id: "OpenTerminal",
                name: "OpenTerminal",
                description: "在终端中打开当前项目目录",
                icon: "terminal",
                isDeveloperEnabled: { OpenTerminalPlugin.enable }
            ),
            PluginInfo(
                id: "OpenCursor",
                name: "OpenCursor",
                description: "在 Cursor 中打开当前项目",
                icon: "cursor.rays",
                isDeveloperEnabled: { OpenCursorPlugin.enable }
            ),
            PluginInfo(
                id: "OpenRemote",
                name: "OpenRemote",
                description: "打开远程仓库链接",
                icon: "link",
                isDeveloperEnabled: { OpenRemotePlugin.enable }
            ),
            // 状态栏插件
            PluginInfo(
                id: "ActivityStatus",
                name: "ActivityStatus",
                description: "在状态栏显示当前长耗时操作的状态",
                icon: "hourglass",
                isDeveloperEnabled: { ActivityStatusPlugin.enable }
            ),
            PluginInfo(
                id: "SmartFile",
                name: "SmartFile",
                description: "在状态栏左侧展示当前文件信息",
                icon: "doc.text",
                isDeveloperEnabled: { SmartFilePlugin.enable }
            ),
            PluginInfo(
                id: "Readme",
                name: "Readme",
                description: "在状态栏提供 README 入口",
                icon: "book",
                isDeveloperEnabled: { ReadmePlugin.enable }
            ),
            PluginInfo(
                id: "Gitignore",
                name: "Gitignore",
                description: "在状态栏提供 .gitignore 查看入口",
                icon: "doc.badge.gearshape",
                isDeveloperEnabled: { GitignorePlugin.enable }
            ),
            PluginInfo(
                id: "License",
                name: "License",
                description: "在状态栏提供 LICENSE 入口",
                icon: "doc.on.doc",
                isDeveloperEnabled: { LicensePlugin.enable }
            )
        ].filter { $0.isDeveloperEnabled() }
    }
}
