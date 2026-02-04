import MagicKit
import OSLog
import SwiftUI

/// 主内容视图，管理应用的整体布局和导航结构
struct ContentView: View, SuperLog {
    nonisolated static let emoji = "📱"
    nonisolated static let verbose = false

    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    /// 导航分栏视图的列可见性状态
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    /// 当前选中的标签页
    @State private var tab: String = "Git"

    /// 状态栏是否可见
    @State private var statusBarVisibility = true

    /// 工具栏是否可见
    @State private var toolbarVisibility = true

    /// 标签页选择器是否可见
    @State private var tabPickerVisibility = true

    /// 项目操作按钮是否可见
    @State private var projectActionsVisibility = true

    /// 控制状态栏布局：true 为全宽（底部跨越左右栏），false 为旧布局（仅 detail 内部）
    var useFullWidthStatusBar: Bool = true

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

    /// 缓存工具栏前导视图的插件和视图对
    @State private var toolbarLeadingViews: [(plugin: SuperPlugin, view: AnyView)] = []

    /// 缓存工具栏后置视图的插件和视图对
    @State private var toolbarTrailingViews: [(plugin: SuperPlugin, view: AnyView)] = []

    /// 缓存插件列表视图的插件和视图对
    @State private var pluginListViews: [(plugin: SuperPlugin, view: AnyView)] = []

    var body: some View {
        Group {
            if useFullWidthStatusBar {
                VStack(spacing: 0) {
                    navigationSplitView(fullWidthStatusBar: true)

                    if statusBarVisibility && g.projectExists {
                        Divider()
                        StatusBar()
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                navigationSplitView(fullWidthStatusBar: false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $app.showSettings) {
            SettingView(defaultTab: settingTabFromString(app.defaultSettingTab))
                .onDisappear {
                    // 重置默认标签
                    app.defaultSettingTab = nil
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            app.openSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openPluginSettings)) { _ in
            app.openPluginSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRepositorySettings)) { _ in
            app.openRepositorySettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCommitStyleSettings)) { _ in
            app.openCommitStyleSettings()
        }
    }

    /// 将字符串转换为设置Tab枚举
    private func settingTabFromString(_ tab: String?) -> SettingView.SettingTab {
        guard let tab = tab else { return .userInfo }
        switch tab {
        case "plugins": return .plugins
        case "repository": return .repository
        case "commitStyle": return .commitStyle
        default: return .userInfo
        }
    }
}

// MARK: - View

extension ContentView {
    /// 创建导航分栏视图
    /// - Parameter fullWidthStatusBar: 是否使用全宽状态栏
    /// - Returns: 配置好的导航分栏视图
    private func navigationSplitView(fullWidthStatusBar: Bool) -> some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Projects()
                .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
                .toolbar(content: {
                    ToolbarItem {
                        BtnAdd()
                    }
                })
        } detail: {
            detailContent(fullWidthStatusBar: fullWidthStatusBar)
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: self.tab, onChangeOfTab)
        .onChange(of: self.columnVisibility, onChangeColumnVisibility)
        .onChange(of: p.plugins.count, onPluginsLoaded)
        .onReceive(p.objectWillChange, perform: onPluginProviderChange)
        .toolbarVisibility(toolbarVisibility ? .visible : .hidden)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                ForEach(toolbarLeadingViews, id: \.plugin.instanceLabel) { item in
                    item.view
                }
            }

            if tabPickerVisibility {
                ToolbarItem(placement: .principal) {
                    Picker("选择标签", selection: $tab) {
                        ForEach(p.tabNames, id: \.self) { tabName in
                            Text(tabName).tag(tabName)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }

            if g.project != nil, projectActionsVisibility {
                ToolbarItemGroup(
                    placement: .cancellationAction,
                    content: {
                        ForEach(toolbarTrailingViews, id: \.plugin.instanceLabel) { item in
                            item.view
                        }
                    })
            }
        })
    }

    /// 创建详情内容视图
    /// - Parameter fullWidthStatusBar: 是否使用全宽状态栏
    /// - Returns: 详情内容视图
    @ViewBuilder
    private func detailContent(fullWidthStatusBar: Bool) -> some View {
        if g.projectExists == false {
            GuideView(
                systemImage: "folder.badge.questionmark",
                title: "项目不存在"
            ).setIconColor(.red.opacity(0.5))
        } else {
            if pluginListViews.isEmpty {
                VStack(spacing: 0) {
                    if let tabDetailView = p.getEnabledTabDetailView(tab: tab) {
                        tabDetailView
                    } else {
                        // 没有可用的详情视图时显示引导界面
                        GuideView(
                            systemImage: "puzzlepiece.extension",
                            title: "暂无可用视图",
                            subtitle: "请在设置中启用相关插件以显示内容",
                            action: {
                                app.openPluginSettings()
                            },
                            actionLabel: "打开插件设置"
                        )
                        .setIconColor(.secondary)
                    }

                    if fullWidthStatusBar == false, statusBarVisibility {
                        StatusBar()
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                HSplitView {
                    VStack(spacing: 0) {
                        ForEach(pluginListViews, id: \.plugin.instanceLabel) { item in
                            item.view
                        }
                    }
                    .frame(idealWidth: 200)
                    .frame(minWidth: 120)
                    .frame(maxWidth: 300)
                    .frame(maxHeight: .infinity)

                    VStack(spacing: 0) {
                        if let tabDetailView = p.getEnabledTabDetailView(tab: tab) {
                            tabDetailView
                        } else {
                            // 没有可用的详情视图时显示引导界面
                            GuideView(
                                systemImage: "puzzlepiece.extension",
                                title: "暂无可用视图",
                                subtitle: "请在设置中启用相关插件以显示内容",
                                action: {
                                    app.openPluginSettings()
                                },
                                actionLabel: "打开插件设置"
                            )
                            .setIconColor(.secondary)
                        }

                        if fullWidthStatusBar == false, statusBarVisibility {
                            StatusBar()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

// MARK: - Event Handler

extension ContentView {
    /// 更新缓存的视图
    func updateCachedViews() {
        if Self.verbose {
            os_log("\(self.t)🔄 Updating cached views")
        }

        // 更新工具栏前导视图
        toolbarLeadingViews = p.getEnabledToolbarLeadingViews()

        // 更新工具栏后置视图
        toolbarTrailingViews = p.getEnabledToolbarTrailingViews()

        // 更新插件列表视图
        pluginListViews = p.getEnabledPluginListViews(tab: tab, project: g.project)

        if Self.verbose {
            os_log("\(self.t)✅ Cached views updated: \(toolbarLeadingViews.count) leading, \(toolbarTrailingViews.count) trailing, \(pluginListViews.count) list views")
        }
    }

    /// 视图出现时的事件处理
    func onAppear() {
        // 如果提供了默认的，则使用默认的
        // 否则使用存储的

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

        if let d = defaultTab {
            if Self.verbose {
                os_log("\(self.t)Setting default tab to: \(d)")
            }
            self.tab = d
        } else {
            // 如果没有提供默认标签页，使用"Git"标签页作为默认值
            if Self.verbose {
                os_log("\(self.t)No default tab provided, using default tab: Git")
            }
            self.tab = "Git"
        }

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

        // 初始化缓存的视图
        updateCachedViews()
    }

    /// 处理项目变更事件
    func onProjectChange() {
        updateCachedViews()
    }

    /// 处理标签页变更事件
    func onChangeOfTab() {
        app.setTab(tab)
        updateCachedViews()
    }

    /// 检查并处理导航分栏视图可见性变化
    /// - Parameter reason: 变化的原因描述
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

    /// 处理列可见性变更事件
    func onChangeColumnVisibility() {
        self.checkColumnVisibility(reason: "onChangeColumnVisibility")
    }

    /// 处理插件加载完成事件
    func onPluginsLoaded() {
        // 当插件列表从空变为非空时，更新缓存的视图
        if !p.plugins.isEmpty {
            if Self.verbose {
                os_log("\(self.t)🔌 Plugins loaded, updating cached views")
            }
            updateCachedViews()
        }
    }

    /// 处理插件提供者变化事件（如插件启用/禁用）
    func onPluginProviderChange() {
        if Self.verbose {
            os_log("\(self.t)🔔 PluginProvider changed, updating cached views")
        }
        updateCachedViews()
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
