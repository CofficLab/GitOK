import Combine
import Foundation
import MagicKit
import ObjectiveC.runtime
import OSLog
import StoreKit
import SwiftData
import SwiftUI

// Auto-generated imports for packaged plugins.
// When adding a new Plugin package, re-run Scripts/generate_plugin_registry.sh.
import GitOKCoreKit
import GitOKUI
import PluginBanner
import PluginCommit
import PluginGitDetail
import PluginGitTab
import PluginIcon

class PluginVM: ObservableObject, SuperLog, SuperThread {
    nonisolated static let emoji = "🧩"
    static let verbose = false

    /// 是否注册所有插件（开发调试用，设为 false 可禁用所有插件）
    static var registerAllPlugins: Bool = true

    @Published private(set) var plugins: [SuperPlugin] = []

    /// 插件设置存储
    private let settingsStore = PluginSettingsStore.shared

    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Plugin Registration

    /// 已注册的插件实例列表
    private var registeredPlugins: [any SuperPlugin] = []

    /// 已使用的插件标签集合（用于检测重复）
    private var usedLabels: Set<String> = []

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    private func register(_ plugin: any SuperPlugin) {
        let label = plugin.instanceLabel

        // 检查标签是否已存在
        if usedLabels.contains(label) {
            let pluginType = String(describing: type(of: plugin))
            os_log(.error, "\(Self.t)❌ Duplicate plugin label '\(label)' in \(pluginType)")
            assertionFailure("Duplicate plugin label: \(label)")
            return
        }

        // 标记该标签已使用
        usedLabels.insert(label)
        registeredPlugins.append(plugin)
    }

    /// 获取所有已注册的插件实例，按 order 排序
    /// - Returns: 排序后的插件实例数组
    private func getAllPlugins() -> [any SuperPlugin] {
        registeredPlugins.sorted { $0.pluginOrder < $1.pluginOrder }
    }

    /// 清空所有注册的插件
    private func clearRegisteredPlugins() {
        registeredPlugins.removeAll()
        usedLabels.removeAll()
    }

    /// 已注册插件数量
    private var registeredCount: Int {
        registeredPlugins.count
    }

    /// 自动发现并注册所有插件
    /// 通过扫描 Objective-C runtime 中所有以 "Plugin" 结尾的类
    private func autoDiscoverAndRegisterPlugins() {
        let start = Date()
        os_log("\(self.t)🚀 Startup begin: autoDiscoverAndRegisterPlugins")

        // 检查是否禁用所有插件注册
        if !Self.registerAllPlugins {
            os_log("\(self.t)⚠️ Plugin registration is disabled via registerAllPlugins=false")
            return
        }

        // 清空已有注册（防止重复注册）
        clearRegisteredPlugins()

        var count: UInt32 = 0
        guard let classList = objc_copyClassList(&count) else {
            os_log(.error, "\(self.t)❌ Failed to get class list")
            return
        }
        defer { free(UnsafeMutableRawPointer(classList)) }

        os_log("\(self.t)🔍 Runtime class count=\(count)")

        if Self.verbose { os_log("\(self.t)🔍 Scanning classes for plugins...") }

        let classes = UnsafeBufferPointer(start: classList, count: Int(count))

        // 临时存储发现的插件，用于排序
        var discoveredPlugins: [(plugin: any SuperPlugin, className: String, order: Int)] = []

        for i in 0 ..< classes.count {
            let cls: AnyClass = classes[i]
            let className = NSStringFromClass(cls)

            // 只检查 GitOK 命名空间下以 "Plugin" 结尾的类
            guard className.hasPrefix("GitOK."), className.hasSuffix("Plugin") else { continue }

            // 尝试获取 shared 单例实例
            let sharedSelector = NSSelectorFromString("shared")
            guard let sharedMethod = class_getClassMethod(cls, sharedSelector) else {
                os_log("\(Self.t)⚠️ No @objc shared found for \(className), skipping")
                continue
            }

            // 调用 shared 方法获取实例
            typealias SharedGetter = @convention(c) (AnyClass, Selector) -> AnyObject?
            let getter = unsafeBitCast(method_getImplementation(sharedMethod), to: SharedGetter.self)

            guard let instance = getter(cls, sharedSelector) else {
                os_log("⚠️ Failed to get shared instance for \(className)")
                continue
            }

            // 检查实例是否符合 SuperPlugin 协议
            guard let plugin = instance as? any SuperPlugin else {
                os_log("⚠️ Instance of \(className) does not conform to SuperPlugin")
                continue
            }

            // 获取插件类型
            let pluginType = type(of: plugin)
            let pluginOrder = plugin.pluginOrder

            // 检查插件是否应该注册
            if !pluginType.shouldRegister {
                if Self.verbose { os_log("\(self.t)⏭️ Skipping plugin (shouldRegister=false): \(className)") }
                continue
            }

            // 添加到临时数组，稍后按 order 排序
            discoveredPlugins.append((plugin, className, pluginOrder))
        }

        // 按 order 排序后注册
        discoveredPlugins.sort { $0.order < $1.order }

        for (plugin, className, order) in discoveredPlugins {
            register(plugin)
            os_log("\(self.t)🧩 Registered plugin #\(order): \(className)")
        }

        os_log("\(self.t)✅ Startup end: autoDiscoverAndRegisterPlugins registered=\(self.registeredCount) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Plugin Query Methods

    /// 检查插件是否被用户启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        // 如果不允许用户切换，则始终启用
        if !plugin.pluginAllowUserToggle {
            return true
        }

        // 检查用户配置
        let pluginId = plugin.instanceLabel
        if PluginSettingsStore.shared.hasUserConfigured(pluginId) {
            return PluginSettingsStore.shared.isPluginEnabled(pluginId, defaultEnabled: plugin.pluginDefaultEnabled)
        }

        // 用户未配置过，使用插件的默认启用状态
        return plugin.pluginDefaultEnabled
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addTabItem() }
    }

    /// 获取可配置的插件信息列表（用于设置界面）
    /// - Returns: 允许用户切换启用/禁用状态的插件信息数组
    var configurablePlugins: [PluginInfo] {
        plugins
            .filter { $0.pluginAllowUserToggle }
            .map { plugin in
                let pluginId = plugin.instanceLabel
                let tableName = plugin.pluginTableName

                return PluginInfo(
                    id: pluginId,
                    name: String(localized: .init(stringLiteral: plugin.pluginDisplayName), table: tableName),
                    description: String(localized: .init(stringLiteral: plugin.pluginDescription), table: tableName),
                    icon: plugin.pluginIconName,
                    defaultEnabled: plugin.pluginDefaultEnabled,
                    isDeveloperEnabled: { true }
                )
            }
            .sorted { $0.name < $1.name }
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    @MainActor
    func getEnabledToolbarLeadingViews(
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        onSelectProject: @escaping GitOKProjectSelectionHandler = { _ in }
    ) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        let context = GitOKPluginContext(
            projects: projects,
            selectedProjectURL: selectedProjectURL,
            isSidebarVisible: isSidebarVisible,
            onProjectSelection: onSelectProject
        )
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarLeadingView(context: context) else { return nil }
            return (
                plugin,
                AnyView(
                    view
                        .environment(\.gitOKProjects, projects)
                        .environment(\.gitOKSelectedProjectURL, selectedProjectURL)
                        .environment(\.gitOKSidebarVisible, isSidebarVisible)
                        .environment(\.gitOKProjectSelectionHandler, onSelectProject)
                )
            )
        }
        .loggingPluginViewBuild("toolbarLeading", start: start, logger: self)
    }

    /// 获取工具栏后置视图
    /// - Returns: 插件及其对应的工具栏后置视图数组
    @MainActor
    func getEnabledToolbarTrailingViews(
        projectURL: URL? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        isGitRepository: Bool = false
    ) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        let context = GitOKPluginContext(
            projectURL: projectURL,
            isGitRepository: isGitRepository,
            remoteTrackingStatus: remoteTrackingStatus
        )
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addToolBarTrailingView(context: context) else { return nil }
            return (
                plugin,
                AnyView(
                    view
                        .environment(\.gitOKProjectURL, projectURL)
                        .environment(\.gitOKRemoteTrackingStatus, remoteTrackingStatus)
                        .environment(\.gitOKIsGitRepository, isGitRepository)
                )
            )
        }
        .loggingPluginViewBuild("toolbarTrailing", start: start, logger: self)
    }

    /// 获取插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 插件及其对应的列表视图数组
    func getEnabledPluginListViews(tab: String, project: Project?) -> [(plugin: SuperPlugin, view: AnyView)] {
        let start = Date()
        return plugins.compactMap { plugin in
            guard isPluginEnabled(plugin) else { return nil }
            guard let view = plugin.addListView(tab: tab, project: project) else { return nil }
            return (plugin, view)
        }
        .loggingPluginViewBuild("list tab=\(tab)", start: start, logger: self)
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    @MainActor
    func getEnabledTabDetailView(tab: String, projectURL: URL? = nil) -> AnyView? {
        let start = Date()
        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            if let view = plugin.addDetailView(for: tab) {
                let elapsed = Date().timeIntervalSince(start)
                if elapsed > 0.2 {
                    os_log("\(self.t)⏱️ Plugin detail view built tab=\(tab) plugin=\(plugin.instanceLabel) elapsed=\(String(format: "%.3f", elapsed))s")
                }
                return AnyView(view.environment(\.gitOKProjectURL, projectURL))
            }
        }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 0.2 {
            os_log("\(self.t)⏱️ Plugin detail view missing tab=\(tab) elapsed=\(String(format: "%.3f", elapsed))s")
        }
        return nil
    }

    // MARK: - StatusBar Views

    /// 获取状态栏前导视图
    /// - Returns: 启用插件的状态栏前导视图数组
    @MainActor
    func getEnabledStatusBarLeadingViews(selectedFilePath: String? = nil, projectPath: String? = nil) -> [AnyView] {
        let context = GitOKPluginContext(
            projectPath: projectPath,
            selectedFilePath: selectedFilePath
        )
        return plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarLeadingView(context: context) }
            .map { view in
                AnyView(
                    view
                        .environment(\.gitOKSelectedFilePath, selectedFilePath)
                        .environment(\.gitOKProjectPath, projectPath)
                )
            }
    }

    /// 获取状态栏中间视图
    /// - Returns: 启用插件的状态栏中间视图数组
    @MainActor
    func getEnabledStatusBarCenterViews(activityStatus: String? = nil) -> [AnyView] {
        let context = GitOKPluginContext(
            activityStatus: activityStatus
        )
        return plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarCenterView(context: context) }
            .map { view in
                AnyView(view.environment(\.gitOKActivityStatus, activityStatus))
            }
    }

    /// 获取状态栏后置视图
    /// - Returns: 启用插件的状态栏后置视图数组
    @MainActor
    func getEnabledStatusBarTrailingViews(
        projectURL: URL? = nil,
        projectPath: String? = nil,
        projectTitle: String? = nil,
        branchName: String? = nil,
        isGitRepository: Bool = false
    ) -> [AnyView] {
        let context = GitOKPluginContext(
            projectURL: projectURL,
            projectPath: projectPath,
            projectTitle: projectTitle,
            branchName: branchName,
            isGitRepository: isGitRepository
        )
        return plugins
            .filter { isPluginEnabled($0) }
            .compactMap { $0.addStatusBarTrailingView(context: context) }
            .map { view in
                AnyView(
                    view
                        .environment(\.gitOKProjectURL, projectURL)
                        .environment(\.gitOKProjectPath, projectPath)
                        .environment(\.gitOKProjectTitle, projectTitle)
                        .environment(\.gitOKBranchName, branchName)
                        .environment(\.gitOKIsGitRepository, isGitRepository)
                )
            }
    }

    // MARK: - Theme Contributions

    @MainActor
    func getThemeContributions() -> [GitOKUIThemeContribution] {
        plugins.flatMap { plugin -> [GitOKUIThemeContribution] in
            guard isPluginEnabled(plugin) else { return [] }
            let pluginOrder = plugin.pluginOrder
            return plugin.addThemeContributions().map { contribution in
                GitOKUIThemeContribution(
                    sortKey: ThemeSortKey(pluginOrder: pluginOrder, themeId: contribution.id),
                    chromeTheme: contribution.chromeTheme,
                    editorThemeId: contribution.editorThemeId,
                    uiTheme: contribution.uiTheme,
                    attachments: contribution.attachments
                )
            }
        }
    }

    // MARK: - Root View Wrapper

    /// 获取所有插件的根视图包裹
    /// 将所有插件提供的根视图包装器依次应用于内容视图。
    /// 包装顺序与插件的 `order` 顺序一致。
    ///
    /// - Parameter content: 原始内容视图
    /// - Returns: 经过所有插件依次包裹后的视图
    func getRootViewWrapper<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        var wrapped: AnyView = AnyView(content())

        for plugin in plugins {
            guard isPluginEnabled(plugin) else { continue }
            wrapped = plugin.wrapRoot(wrapped)
        }

        return wrapped
    }

    // MARK: - Initialization

    init() {
        let start = Date()
        os_log("\(Self.t)🚀 Startup begin: PluginVM.init")

        // 自动发现并注册所有插件
        autoDiscoverAndRegisterPlugins()
        registerPackagedPlugins()

        // 从内部注册表获取所有已注册的插件实例
        self.plugins = getAllPlugins()
        os_log("\(Self.t)✅ Startup step: PluginVM plugins sorted count=\(self.plugins.count)")

        // 订阅设置变化，当设置改变时触发 UI 更新
        settingsStore.$settings
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        os_log("\(Self.t)✅ Startup end: PluginVM.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Custom Plugin Providers

    /// Plugins that need custom view providers (closures referencing APP-internal types).
    /// Key = instanceLabel of the packaged plugin, Value = adapter with injected closures.
    private var customProviders: [String: any SuperPlugin] {
        [
            GitDetailPlugin.metadata.id: PackagedPluginAdapter<GitDetailPlugin>(
                detailViewProvider: { tab in
                    guard tab == GitTabPlugin.metadata.displayName else { return nil }
                    return AnyView(GitDetail.shared)
                }
            ),
            CommitPlugin.metadata.id: PackagedPluginAdapter<CommitPlugin>(
                listViewProvider: { tab, project in
                    guard tab == "Git", let project, project.isGitRepo else { return nil }
                    return AnyView(CommitList.shared)
                }
            ),
            BannerPlugin.metadata.id: PackagedPluginAdapter<BannerPlugin>(
                detailViewProvider: { tab in
                    guard tab == "Banner" else { return nil }
                    return AnyView(PluginBanner.BannerDetailLayout.shared)
                }
            ),
            IconPlugin.metadata.id: PackagedPluginAdapter<IconPlugin>(
                detailViewProvider: { tab in
                    guard tab == "Icon" else { return nil }
                    return AnyView(PluginIcon.IconDetailLayout.shared)
                }
            ),
        ]
    }

    /// Register all packaged plugins using the auto-generated registry.
    /// Plugins with custom view providers are handled separately via `customProviders`.
    private func registerPackagedPlugins() {
        let customIds = Set(customProviders.keys)

        // Register default adapters, skipping those that have custom providers
        GeneratedPluginRegistry.registerDefaultAdapters { adapter in
            let label = adapter.instanceLabel
            if customIds.contains(label) {
                // Will be registered below with custom closures
                return
            }
            self.register(adapter)
        }

        // Register plugins with custom view providers (closures referencing APP-internal types)
        for (_, adapter) in customProviders {
            if type(of: adapter).shouldRegister {
                register(adapter)
            }
        }
    }
}

private extension Array where Element == (plugin: SuperPlugin, view: AnyView) {
    func loggingPluginViewBuild(_ label: String, start: Date, logger: PluginVM) -> Self {
        let elapsed = Date().timeIntervalSince(start)
        if elapsed > 0.2 {
            os_log("\(logger.t)⏱️ Plugin views built type=\(label) count=\(self.count) elapsed=\(String(format: "%.3f", elapsed))s")
        }
        return self
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
