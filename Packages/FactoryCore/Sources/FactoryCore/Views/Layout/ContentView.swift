import GitOKAppCore
import GitOKUI
import KitGitOKCore
import MagicAlert
import KitGitOKSupport
import AppKit
import OSLog
import SwiftUI

/// 主内容视图，管理应用的整体布局和导航结构
struct ContentView: View, SuperLog {
    nonisolated public static let emoji = "📱"
    nonisolated public static let verbose = false

    @EnvironmentObject var app: AppVM
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var p: PluginService
    @EnvironmentObject var vm: ProjectVM
    /// 工具栏 provider（由装配层注入环境对象）：顶栏渲染与工具栏项由它持有。
    @EnvironmentObject var toolbarProvider: DefaultGitOKToolbarProvider

    /// 导航分栏视图的列可见性状态
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// 状态栏是否可见
    @State private var statusBarVisibility = true

    /// 默认状态栏可见性
    var defaultStatusBarVisibility: Bool? = nil

    /// 默认选中的标签页
    var defaultTab: GitOKAppTab? = nil

    /// 默认列可见性
    var defaultColumnVisibility: NavigationSplitViewVisibility? = nil

    /// 默认工具栏可见性
    var defaultToolbarVisibility: Bool? = nil

    /// 默认项目操作可见性
    var defaultProjectActionsVisibility: Bool? = nil

    /// 默认标签页可见性
    var defaultTabVisibility: Bool? = nil

    /// 缓存插件 Rail 视图贡献
    @State private var pluginRailViews: [GitOKRailItem] = []

    /// 当前选中的 Rail 项
    @State private var selectedRailID: String?

    var body: some View {
        navigationSplitView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .focusedSceneObject(vm)
    }
}

// MARK: - View

extension ContentView {
    /// 创建导航分栏视图
    /// - Returns: 配置好的导航分栏视图
    private func navigationSplitView() -> some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            DetailView(
                tab: app.currentTab,
                pluginRailViews: pluginRailViews,
                selectedRailID: $selectedRailID,
                statusBarVisibility: statusBarVisibility
            )
        }
        // 隐藏原生 window toolbar：工具栏内容已由 toolbar provider 的自绘顶栏承担，
        // 同时避免 NavigationSplitView 自动安装带侧栏切换的原生统一工具栏。
        .toolbar(.hidden, for: .windowToolbar)
        .onAppear(perform: onAppear)
        .onDisappear(perform: clearCachedViews)
        .onChange(of: vm.project, onProjectChange)
        .onChange(of: vm.projectGitRepositoryStateToken, onProjectGitRepositoryStateChange)
        .onChange(of: app.currentTab, onChangeOfTab)
        .onChange(of: self.columnVisibility, onChangeColumnVisibility)
        .onChange(of: p.registeredPluginCount, onPluginsLoaded)
        .onPluginProviderChange(if: p.hasPlugins, provider: p, perform: onPluginProviderChange)
        .onReceive(g.$branch) { _ in
            updateCachedViews()
        }
        .onReceive(app.$sidebarVisibility) { visible in
            let target: NavigationSplitViewVisibility = visible ? .all : .detailOnly
            if columnVisibility != target {
                columnVisibility = target
            }
            updateCachedViews()
        }
    }
}

// MARK: - Event Handler

extension ContentView {
    /// 更新缓存的视图
    func updateCachedViews() {
        guard p.hasPlugins else {
            clearCachedViews()
            return
        }

        let start = Date()
        if Self.verbose {
            os_log("\(self.t)🔄 UpdateCachedViews begin tab=\(app.currentTab.rawValue) project=\(vm.project?.path ?? "nil") plugins=\(p.registeredPluginCount)")
        }

        let leadingStart = Date()
        let repositoryHandlers = PluginRepositoryContextFactory.handlers(data: g, projectVM: vm)
        let leadingViews = p.getEnabledToolbarLeadingViews(
            projectURL: vm.project?.url,
            branchName: g.branch?.name,
            isGitRepository: vm.currentProjectIsGitRepository,
            projects: g.projects.map {
                GitOKProjectSummary(url: $0.url, title: $0.title, path: $0.path)
            },
            selectedProjectURL: vm.project?.url,
            isSidebarVisible: app.sidebarVisibility,
            onSelectProject: { selectedURL in
                guard let project = g.projects.first(where: { $0.url == selectedURL }) else { return }
                vm.setProject(project, reason: "ProjectPicker")
            },
            canImportRepository: repositoryHandlers.canImportRepository,
            onProjectExists: repositoryHandlers.onProjectExists,
            onRepositoryImported: repositoryHandlers.onRepositoryImported,
            onActivityStatusUpdate: repositoryHandlers.onActivityStatusUpdate,
            onInfoMessage: repositoryHandlers.onInfoMessage
        )
        toolbarProvider.setLeadingItems(leadingViews)
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews leading count=\(leadingViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(leadingStart)))s")
        }

        let trailingStart = Date()
        let trailingViews = p.getEnabledToolbarTrailingViews(
            projectURL: vm.project?.url,
            branchName: g.branch?.name,
            remoteTrackingStatus: GitOKRemoteTrackingStatus(
                ahead: vm.aheadCount,
                behind: vm.behindCount,
                hasUpstream: vm.hasUpstream
            ),
            isGitRepository: vm.currentProjectIsGitRepository
        )
        toolbarProvider.setTrailingItems(trailingViews)
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews trailing count=\(trailingViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(trailingStart)))s")
        }

        let railStart = Date()
        pluginRailViews = p.getEnabledRailViews(
            tab: app.currentTab,
            project: vm.project,
            isGitRepository: vm.currentProjectIsGitRepository
        )
        if let selectedRailID,
           pluginRailViews.contains(where: { $0.id == selectedRailID }) == false {
            self.selectedRailID = pluginRailViews.first?.id
        } else if selectedRailID == nil {
            self.selectedRailID = pluginRailViews.first?.id
        }
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews rail count=\(pluginRailViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(railStart)))s")
        }

        if Self.verbose {
            os_log("\(self.t)✅ Cached views updated: \(leadingViews.count) leading, \(trailingViews.count) trailing, \(pluginRailViews.count) rail views")
            os_log("\(self.t)✅ UpdateCachedViews end elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    func clearCachedViews() {
        toolbarProvider.setLeadingItems([])
        toolbarProvider.setTrailingItems([])
        pluginRailViews.removeAll()
        selectedRailID = nil
    }

    /// 视图出现时的事件处理
    func onAppear() {
        let start = Date()
        if Self.verbose {
            os_log("\(self.t)🚀 ContentView.onAppear begin")
        }

        if let d = defaultColumnVisibility {
            self.columnVisibility = d

            let sidebarVisibility = d == .detailOnly ? false : true
            app.setSidebarVisibility(sidebarVisibility, reason: "defaultColumnVisibility")
        } else {
            if app.sidebarVisibility == true {
                self.columnVisibility = .all
            } else {
                self.columnVisibility = .detailOnly
            }
        }

        selectResolvedTab(preferred: defaultTab, reason: "onAppear")

        if let d = defaultStatusBarVisibility {
            self.statusBarVisibility = d
        }

        if let d = defaultToolbarVisibility {
            toolbarProvider.setToolbarVisible(d)
        }

        if let d = defaultTabVisibility {
            toolbarProvider.setTabPickerVisible(d)
        }

        if let d = defaultProjectActionsVisibility {
            toolbarProvider.setProjectActionsVisible(d)
        }

        refreshCurrentBranch(reason: "ContentView.onAppear")
        updateCachedViews()

        if Self.verbose {
            os_log("\(self.t)✅ ContentView.onAppear end tab=\(app.currentTab.rawValue) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    /// 处理项目变更事件
    func onProjectChange() {
        refreshCurrentBranch(reason: "ContentView.onProjectChange")
        updateCachedViews()
    }

    func onProjectGitRepositoryStateChange() {
        refreshCurrentBranch(reason: "ContentView.onProjectGitRepositoryStateChange")
        updateCachedViews()
    }

    func refreshCurrentBranch(reason: String) {
        g.refreshCurrentBranch(
            project: vm.project,
            isGitRepository: vm.currentProjectIsGitRepository,
            reason: reason
        )
    }

    /// 处理标签页变更事件
    func onChangeOfTab() {
        updateCachedViews()
    }

    func checkColumnVisibility(reason: String) {
        if Self.verbose {
            os_log("\(self.t)Check column visibility: \(reason)")
        }
        if columnVisibility == .detailOnly {
            app.hideSidebar()
        } else {
            app.showSidebar(reason: "ContentView.onCheckColumnVisibility.TwoColumnMode")
        }
    }

    func onChangeColumnVisibility() {
        self.checkColumnVisibility(reason: "onChangeColumnVisibility")
    }

    func onPluginsLoaded() {
        guard p.hasPlugins else {
            clearCachedViews()
            return
        }

        if Self.verbose {
            os_log("\(self.t)🔌 Plugins loaded, updating cached views")
        }
        selectResolvedTab(preferred: defaultTab, reason: "pluginsLoaded")
        updateCachedViews()
    }

    func onPluginProviderChange() {
        guard p.hasPlugins else {
            clearCachedViews()
            return
        }
        if Self.verbose {
            os_log("\(self.t)🔔 PluginProvider changed, updating cached views")
        }
        updateCachedViews()
    }

    private func selectResolvedTab(preferred: GitOKAppTab?, reason: String) {
        let resolvedTab = resolvedInitialTab(preferred: preferred)
        guard app.currentTab != resolvedTab else { return }

        if Self.verbose {
            os_log("\(self.t)Selected tab resolved reason=\(reason) tab=\(resolvedTab.rawValue)")
        }

        app.setTab(resolvedTab)
    }

    private func resolvedInitialTab(preferred: GitOKAppTab?) -> GitOKAppTab {
        let visibleTabs = AppTabCatalog.visibleTabs

        if let preferred, visibleTabs.contains(preferred) {
            return preferred
        }

        if visibleTabs.contains(app.currentTab) {
            return app.currentTab
        }

        return AppTabCatalog.defaultTab
    }
}

private extension View {
    @ViewBuilder
    func onPluginProviderChange(
        if isEnabled: Bool,
        provider: PluginService,
        perform action: @escaping () -> Void
    ) -> some View {
        if isEnabled {
            onReceive(provider.objectWillChange) { _ in
                action()
            }
        } else {
            self
        }
    }
}
