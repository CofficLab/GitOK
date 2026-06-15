import GitOKAppCore
import GitOKCoreKit
import MagicAlert
import GitOKSupportKit
import AppKit
import OSLog
import SwiftUI

/// 主内容视图，管理应用的整体布局和导航结构
struct ContentView: View, SuperLog {
    nonisolated static let emoji = "📱"
    nonisolated static let verbose = false

    @EnvironmentObject var app: AppVM
    @EnvironmentObject var g: DataVM
    @EnvironmentObject var p: PluginService
    @EnvironmentObject var vm: ProjectVM

    /// 导航分栏视图的列可见性状态
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// 当前选中的标签页
    @State private var tab: String = ""

    /// 状态栏是否可见
    @State private var statusBarVisibility = true

    /// 工具栏是否可见
    @State private var toolbarVisibility = true

    /// 标签页选择器是否可见
    @State private var tabPickerVisibility = true

    /// 项目操作按钮是否可见
    @State private var projectActionsVisibility = true

    /// 默认状态栏可见性
    var defaultStatusBarVisibility: Bool? = nil

    /// 默认选中的标签页
    var defaultTab: String? = nil

    /// 默认列可见性
    var defaultColumnVisibility: NavigationSplitViewVisibility? = nil

    /// 默认工具栏可见性
    var defaultToolbarVisibility: Bool? = nil

    /// 默认项目操作可见性
    var defaultProjectActionsVisibility: Bool? = nil

    /// 默认标签页可见性
    var defaultTabVisibility: Bool? = nil

    /// 缓存工具栏前导视图贡献
    @State private var toolbarLeadingViews: [GitOKPluginViewContribution] = []

    /// 缓存工具栏后置视图贡献
    @State private var toolbarTrailingViews: [GitOKPluginViewContribution] = []

    /// 缓存插件列表视图贡献
    @State private var pluginListViews: [GitOKPluginViewContribution] = []

    var body: some View {
        navigationSplitView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $app.showSettings) {
                SettingView(defaultTabID: app.defaultSettingTab ?? "userInfo")
                    .onDisappear {
                        // 重置默认标签
                        app.defaultSettingTab = nil
                    }
            }
            .focusedSceneObject(vm)
    }

    /// 将字符串转换为设置Tab id（保留供菜单命令使用）
    private func settingTabFromString(_ tab: String?) -> String {
        tab ?? "userInfo"
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
                tab: tab,
                pluginListViews: pluginListViews,
                statusBarVisibility: statusBarVisibility
            )
        }
        .gitOKToolbarVisibility(toolbarVisibility)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    ForEach(toolbarLeadingViews) { item in
                        item.view
                    }
                }
            }

            if tabPickerVisibility, p.tabNames.isEmpty == false {
                ToolbarItem(placement: .principal) {
                    Picker(String(localized: "Select Tab"), selection: $tab) {
                        ForEach(p.tabNames, id: \.self) { tabName in
                            Text(tabName).tag(tabName)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if vm.project != nil, projectActionsVisibility {
                ToolbarItemGroup(placement: .cancellationAction) {
                    ForEach(toolbarTrailingViews) { item in
                        item.view
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
        .onDisappear(perform: clearCachedViews)
        .onChange(of: vm.project, onProjectChange)
        .onChange(of: vm.projectGitRepositoryStateToken, onProjectGitRepositoryStateChange)
        .onChange(of: self.tab, onChangeOfTab)
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

private extension View {
    @ViewBuilder
    func gitOKToolbarVisibility(_ visible: Bool) -> some View {
        if #available(macOS 15.0, *) {
            self.toolbarVisibility(visible ? .visible : .hidden)
        } else {
            self.background(WindowToolbarVisibilityBridge(isVisible: visible))
        }
    }
}

private struct WindowToolbarVisibilityBridge: NSViewRepresentable {
    let isVisible: Bool

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.toolbar?.isVisible = isVisible
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
            os_log("\(self.t)🔄 UpdateCachedViews begin tab=\(tab) project=\(vm.project?.path ?? "nil") plugins=\(p.registeredPluginCount)")
        }

        let leadingStart = Date()
        let repositoryHandlers = PluginRepositoryContextFactory.handlers(data: g, projectVM: vm)
        toolbarLeadingViews = p.getEnabledToolbarLeadingViews(
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
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews leading count=\(toolbarLeadingViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(leadingStart)))s")
        }

        let trailingStart = Date()
        toolbarTrailingViews = p.getEnabledToolbarTrailingViews(
            projectURL: vm.project?.url,
            branchName: g.branch?.name,
            remoteTrackingStatus: GitOKRemoteTrackingStatus(
                ahead: vm.aheadCount,
                behind: vm.behindCount,
                hasUpstream: vm.hasUpstream
            ),
            isGitRepository: vm.currentProjectIsGitRepository
        )
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews trailing count=\(toolbarTrailingViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(trailingStart)))s")
        }

        let listStart = Date()
        pluginListViews = p.getEnabledPluginListViews(
            tab: tab,
            project: vm.project,
            isGitRepository: vm.currentProjectIsGitRepository
        )
        if Self.verbose {
            os_log("\(self.t)✅ UpdateCachedViews list count=\(pluginListViews.count) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(listStart)))s")
        }

        if Self.verbose {
            os_log("\(self.t)✅ Cached views updated: \(toolbarLeadingViews.count) leading, \(toolbarTrailingViews.count) trailing, \(pluginListViews.count) list views")
            os_log("\(self.t)✅ UpdateCachedViews end elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    func clearCachedViews() {
        toolbarLeadingViews.removeAll()
        toolbarTrailingViews.removeAll()
        pluginListViews.removeAll()
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
            self.toolbarVisibility = d
        }

        if let d = defaultTabVisibility {
            self.tabPickerVisibility = d
        }

        if let d = defaultProjectActionsVisibility {
            self.projectActionsVisibility = d
        }

        refreshCurrentBranch(reason: "ContentView.onAppear")
        updateCachedViews()

        if Self.verbose {
            os_log("\(self.t)✅ ContentView.onAppear end tab=\(tab) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
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
        app.setTab(tab)
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

    private func selectResolvedTab(preferred: String?, reason: String) {
        let resolvedTab = resolvedInitialTab(preferred: preferred)
        guard tab != resolvedTab else {
            if app.currentTab != resolvedTab {
                app.setTab(resolvedTab)
            }
            return
        }

        if Self.verbose {
            os_log("\(self.t)Selected tab resolved reason=\(reason) tab=\(resolvedTab)")
        }

        tab = resolvedTab
        app.setTab(resolvedTab)
    }

    private func resolvedInitialTab(preferred: String?) -> String {
        let tabNames = p.tabNames

        if tabNames.isEmpty {
            return preferred ?? ""
        }

        if let preferred, preferred.isEmpty == false {
            if tabNames.contains(preferred) {
                return preferred
            }
        }

        if app.currentTab.isEmpty == false {
            if tabNames.contains(app.currentTab) {
                return app.currentTab
            }
        }

        return tabNames.first ?? ""
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

// MARK: - Preview

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
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
