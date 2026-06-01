import Combine
import Foundation
import MagicKit
import OSLog
import SwiftUI

import GitOKCoreKit
import GitOKPluginRegistry
import GitOKUI

@MainActor
class PluginVM: ObservableObject, SuperLog, SuperThread {
    nonisolated static let emoji = "🧩"
    static let verbose = false

    /// 是否注册所有插件（开发调试用，设为 false 可禁用所有插件）
    static var registerAllPlugins: Bool = true

    @Published private(set) var plugins: [SuperPlugin] = []

    private lazy var runtime = GitOKPluginRuntime()

    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Plugin Registration

    /// 注册一个插件实例
    /// - Parameter plugin: 要注册的插件实例
    private func register(_ plugin: any SuperPlugin) {
        runtime.register(plugin)
    }

    /// 获取所有已注册的插件实例，按 order 排序
    /// - Returns: 排序后的插件实例数组
    private func getAllPlugins() -> [any SuperPlugin] {
        runtime.sortedRegisteredPlugins()
    }

    /// 清空所有注册的插件
    private func clearRegisteredPlugins() {
        runtime.clearRegisteredPlugins()
    }

    /// 已注册插件数量
    private var registeredCount: Int {
        runtime.registeredCount
    }

    // MARK: - Plugin Query Methods

    /// 检查插件是否被用户启用
    /// - Parameter plugin: 要检查的插件
    /// - Returns: 如果插件被启用则返回true
    func isPluginEnabled(_ plugin: any SuperPlugin) -> Bool {
        guard hasPlugins else { return false }
        return runtime.isPluginEnabled(plugin)
    }

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        guard hasPlugins else { return [] }
        return runtime.tabNames
    }

    /// 获取可配置的插件信息列表（用于设置界面）
    /// - Returns: 允许用户切换启用/禁用状态的插件信息数组
    var configurablePlugins: [PluginInfo] {
        guard hasPlugins else { return [] }
        return runtime.configurablePlugins
    }

    var hasPlugins: Bool {
        !plugins.isEmpty
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    @MainActor
    func getEnabledToolbarLeadingViews(
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        onSelectProject: @escaping GitOKProjectSelectionHandler = { _ in },
        canCloneRepository: Bool = false,
        onProjectExists: @escaping GitOKProjectExistenceHandler = { _ in false },
        onCloneRepositoryCompleted: @escaping GitOKCloneRepositoryCompletionHandler = { _ in false },
        onActivityStatusUpdate: @escaping GitOKActivityStatusUpdateHandler = { _ in },
        onInfoMessage: @escaping GitOKUserMessageHandler = { _ in }
    ) -> [(plugin: SuperPlugin, view: AnyView)] {
        guard hasPlugins else { return [] }
        let start = Date()
        let context = GitOKPluginContext(
            projects: projects,
            selectedProjectURL: selectedProjectURL,
            isSidebarVisible: isSidebarVisible,
            canCloneRepository: canCloneRepository,
            onProjectSelection: onSelectProject,
            onProjectExists: onProjectExists,
            onCloneRepositoryCompleted: onCloneRepositoryCompleted,
            onActivityStatusUpdate: onActivityStatusUpdate,
            onInfoMessage: onInfoMessage
        )
        return runtime.enabledToolbarLeadingViews(context: context)
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
        guard hasPlugins else { return [] }
        let start = Date()
        let context = GitOKPluginContext(
            projectURL: projectURL,
            isGitRepository: isGitRepository,
            remoteTrackingStatus: remoteTrackingStatus
        )
        return runtime.enabledToolbarTrailingViews(context: context)
        .loggingPluginViewBuild("toolbarTrailing", start: start, logger: self)
    }

    /// 获取插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 插件及其对应的列表视图数组
    @MainActor
    func getEnabledPluginListViews(tab: String, project: Project?) -> [(plugin: SuperPlugin, view: AnyView)] {
        guard hasPlugins else { return [] }
        let start = Date()
        let context = GitOKPluginContext(
            projectURL: project?.url,
            projectPath: project.map { $0.url.path },
            projectTitle: project?.title,
            isGitRepository: project?.isGitRepo ?? false
        )
        return runtime.enabledListViews(tab: tab, projectURL: project?.url, context: context)
        .loggingPluginViewBuild("list tab=\(tab)", start: start, logger: self)
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    @MainActor
    func getEnabledTabDetailView(tab: String, projectURL: URL? = nil) -> AnyView? {
        guard hasPlugins else { return nil }
        let start = Date()
        let context = GitOKPluginContext(projectURL: projectURL)
        if let view = runtime.enabledDetailView(for: tab, context: context) {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed > 0.2 {
                os_log("\(self.t)⏱️ Plugin detail view built tab=\(tab) elapsed=\(String(format: "%.3f", elapsed))s")
            }
            return view
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
        guard hasPlugins else { return [] }
        let context = GitOKPluginContext(
            projectPath: projectPath,
            selectedFilePath: selectedFilePath
        )
        return runtime.enabledStatusBarLeadingViews(context: context)
    }

    /// 获取状态栏中间视图
    /// - Returns: 启用插件的状态栏中间视图数组
    @MainActor
    func getEnabledStatusBarCenterViews(activityStatus: String? = nil) -> [AnyView] {
        guard hasPlugins else { return [] }
        let context = GitOKPluginContext(
            activityStatus: activityStatus
        )
        return runtime.enabledStatusBarCenterViews(context: context)
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
        guard hasPlugins else { return [] }
        let context = GitOKPluginContext(
            projectURL: projectURL,
            projectPath: projectPath,
            projectTitle: projectTitle,
            branchName: branchName,
            isGitRepository: isGitRepository
        )
        return runtime.enabledStatusBarTrailingViews(context: context)
    }

    // MARK: - Theme Contributions

    @MainActor
    func getThemeContributions() -> [GitOKUIThemeContribution] {
        guard hasPlugins else { return [] }
        return runtime.themeContributions()
    }

    // MARK: - Root View Wrapper

    /// 获取所有插件的根视图包裹
    /// 将所有插件提供的根视图包装器依次应用于内容视图。
    /// 包装顺序与插件的 `order` 顺序一致。
    ///
    /// - Parameter content: 原始内容视图
    /// - Returns: 经过所有插件依次包裹后的视图
    func getRootViewWrapper<Content: View>(@ViewBuilder content: () -> Content) -> AnyView {
        guard hasPlugins else { return AnyView(content()) }
        return runtime.rootViewWrapper(content: content)
    }

    // MARK: - Initialization

    init() {
        let start = Date()
        os_log("\(Self.t)🚀 Startup begin: PluginVM.init")

        if GeneratedPluginRegistry.hasDefaultAdapters {
            registerPackagedPlugins()
        }

        // 从内部注册表获取所有已注册的插件实例
        self.plugins = GeneratedPluginRegistry.hasDefaultAdapters ? getAllPlugins() : []
        os_log("\(Self.t)✅ Startup step: PluginVM plugins sorted count=\(self.plugins.count)")

        // 订阅设置变化，当设置改变时触发 UI 更新
        if hasPlugins {
            PluginSettingsStore.shared.$settings
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }

        os_log("\(Self.t)✅ Startup end: PluginVM.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Custom Plugin Providers

    /// Register all packaged plugins using the auto-generated registry.
    private func registerPackagedPlugins() {
        if !Self.registerAllPlugins {
            os_log("\(self.t)⚠️ Plugin registration is disabled via registerAllPlugins=false")
            return
        }

        clearRegisteredPlugins()

        GeneratedPluginRegistry.registerDefaultAdapters(adapterFactory: AppPluginAdapterFactory()) { adapter in
            self.register(adapter)
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
