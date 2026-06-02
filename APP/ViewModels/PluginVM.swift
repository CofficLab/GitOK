import Combine
import Foundation
import SwiftUI

import GitOKCoreKit
import GitOKUI

@MainActor
class PluginVM: ObservableObject {
    typealias PluginRegistrationHandler = (
        _ adapterFactory: any GitOKPluginAdapterFactory,
        _ register: (any SuperPlugin) -> Void
    ) -> Void

    private var runtime: GitOKPluginRuntime?

    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Plugin Query Methods

    /// 获取所有可用的标签页名称
    /// - Returns: 标签页名称数组
    var tabNames: [String] {
        guard hasPlugins, let runtime else { return [] }
        return runtime.tabNames
    }

    /// 获取可配置的插件信息列表（用于设置界面）
    /// - Returns: 允许用户切换启用/禁用状态的插件信息数组
    var configurablePlugins: [PluginInfo] {
        guard hasPlugins, let runtime else { return [] }
        return runtime.configurablePlugins
    }

    var hasPlugins: Bool {
        registeredPluginCount > 0
    }

    var registeredPluginCount: Int {
        runtime?.registeredCount ?? 0
    }

    /// 获取工具栏前导视图
    /// - Returns: 插件及其对应的工具栏前导视图数组
    @MainActor
    func getEnabledToolbarLeadingViews(
        projects: [GitOKProjectSummary] = [],
        selectedProjectURL: URL? = nil,
        isSidebarVisible: Bool = true,
        onSelectProject: @escaping GitOKProjectSelectionHandler = { _ in },
        canImportRepository: Bool = false,
        onProjectExists: @escaping GitOKProjectExistenceHandler = { _ in false },
        onRepositoryImported: @escaping GitOKRepositoryImportCompletionHandler = { _ in false },
        onActivityStatusUpdate: @escaping GitOKActivityStatusUpdateHandler = { _ in },
        onInfoMessage: @escaping GitOKUserMessageHandler = { _ in }
    ) -> [GitOKPluginViewContribution] {
        guard hasPlugins, let runtime else { return [] }
        let context = GitOKPluginContext(
            projects: projects,
            selectedProjectURL: selectedProjectURL,
            isSidebarVisible: isSidebarVisible,
            canImportRepository: canImportRepository,
            onProjectSelection: onSelectProject,
            onProjectExists: onProjectExists,
            onRepositoryImported: onRepositoryImported,
            onActivityStatusUpdate: onActivityStatusUpdate,
            onInfoMessage: onInfoMessage
        )
        return runtime.enabledToolbarLeadingViews(context: context)
    }

    /// 获取工具栏后置视图
    /// - Returns: 插件及其对应的工具栏后置视图数组
    @MainActor
    func getEnabledToolbarTrailingViews(
        projectURL: URL? = nil,
        remoteTrackingStatus: GitOKRemoteTrackingStatus? = nil,
        isGitRepository: Bool = false
    ) -> [GitOKPluginViewContribution] {
        guard hasPlugins, let runtime else { return [] }
        let context = GitOKPluginContext(
            projectURL: projectURL,
            isGitRepository: isGitRepository,
            remoteTrackingStatus: remoteTrackingStatus
        )
        return runtime.enabledToolbarTrailingViews(context: context)
    }

    /// 获取插件列表视图
    /// - Parameters:
    ///   - tab: 当前选中的标签页
    ///   - project: 当前选中的项目
    /// - Returns: 插件及其对应的列表视图数组
    @MainActor
    func getEnabledPluginListViews(tab: String, project: Project?) -> [GitOKPluginViewContribution] {
        guard hasPlugins, let runtime else { return [] }
        let context = GitOKPluginContext(
            projectURL: project?.url,
            projectPath: project.map { $0.url.path },
            projectTitle: project?.title,
            isGitRepository: project?.isGitRepo ?? false
        )
        return runtime.enabledListViews(tab: tab, projectURL: project?.url, context: context)
    }

    /// 获取标签页详情视图
    /// - Parameter tab: 标签页标识符
    /// - Returns: 如果找到标签页插件，则返回其详情视图，否则返回nil
    @MainActor
    func getEnabledTabDetailView(tab: String, projectURL: URL? = nil) -> AnyView? {
        guard hasPlugins, let runtime else { return nil }
        let context = GitOKPluginContext(projectURL: projectURL)
        return runtime.enabledDetailView(for: tab, context: context)
    }

    // MARK: - StatusBar Views

    /// 获取状态栏前导视图
    /// - Returns: 启用插件的状态栏前导视图数组
    @MainActor
    func getEnabledStatusBarLeadingViews(selectedFilePath: String? = nil, projectPath: String? = nil) -> [AnyView] {
        guard hasPlugins, let runtime else { return [] }
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
        guard hasPlugins, let runtime else { return [] }
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
        guard hasPlugins, let runtime else { return [] }
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
        guard hasPlugins, let runtime else { return [] }
        return runtime.themeContributions()
    }

    // MARK: - Root View Wrapper

    /// 获取所有插件的根视图包裹
    /// 将所有插件提供的根视图包装器依次应用于内容视图。
    /// 包装顺序与插件的 `order` 顺序一致。
    ///
    /// - Parameter content: 原始内容视图
    /// - Returns: 经过所有插件依次包裹后的视图
    func getRootViewWrapper<Content: View>(
        context: GitOKPluginContext,
        @ViewBuilder content: () -> Content
    ) -> AnyView {
        guard hasPlugins, let runtime else { return AnyView(content()) }
        return runtime.rootViewWrapper(context: context, content: content)
    }

    // MARK: - Initialization

    init(
        adapterFactory: (any GitOKPluginAdapterFactory)? = nil,
        registerPackagedPlugins: PluginRegistrationHandler? = nil
    ) {
        let pluginRuntime = registerPackagedPlugins == nil ? nil : GitOKPluginRuntime()
        self.runtime = pluginRuntime

        if let registerPackagedPlugins {
            let adapterFactory = adapterFactory ?? DefaultGitOKPluginAdapterFactory()
            registerPackagedPluginAdapters(adapterFactory, registerPackagedPlugins)
        }

        // 订阅设置变化，当设置改变时触发 UI 更新
        if hasPlugins {
            PluginSettingsStore.shared.$settings
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Custom Plugin Providers

    /// Register all packaged plugins supplied by the registry package.
    private func registerPackagedPluginAdapters(
        _ adapterFactory: any GitOKPluginAdapterFactory,
        _ registerPackagedPlugins: PluginRegistrationHandler
    ) {
        guard let runtime else { return }

        runtime.clearRegisteredPlugins()

        registerPackagedPlugins(adapterFactory) { adapter in
            runtime.register(adapter)
        }
    }
}
