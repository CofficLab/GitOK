import MagicCore
import OSLog
import SwiftUI

struct ContentView: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var tab: String = GitPlugin.label
    @State private var statusBarVisibility = true
    @State private var toolbarVisibility = true
    @State private var tabPickerVisibility = true
    @State private var projectActionsVisibility = true

    var defaultStatusBarVisibility: Bool? = nil
    var defaultTab: String? = nil
    var defaultColumnVisibility: NavigationSplitViewVisibility? = nil
    var defaultToolbarVisibility: Bool? = nil
    var defaultProjectActionsVisibility: Bool? = nil
    var defaultTabVisibility: Bool? = nil

    // MARK: - Computed Properties for Performance Optimization

    /// 缓存工具栏前导视图的插件和视图对
    private var toolbarLeadingViews: [(plugin: SuperPlugin, view: AnyView)] {
        p.plugins.compactMap { plugin in
            if let view = plugin.addToolBarLeadingView() {
                return (plugin, view)
            }
            return nil
        }
    }

    /// 缓存工具栏后置视图的插件和视图对
    private var toolbarTrailingViews: [(plugin: SuperPlugin, view: AnyView)] {
        p.plugins.compactMap { plugin in
            if let view = plugin.addToolBarTrailingView() {
                return (plugin, view)
            }
            return nil
        }
    }

    private var pluginListViews: [(plugin: SuperPlugin, view: AnyView)] {
        p.plugins.compactMap { plugin in
            if let view = plugin.addListView(tab: tab, project: g.project) {
                return (plugin, view)
            }
            return nil
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Projects()
                .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
                .toolbar(content: {
                    ToolbarItem {
                        BtnAdd()
                    }
                })
        } detail: {
            if g.projectExists == false {
                GuideView(
                    systemImage: "folder.badge.questionmark",
                    title: "项目不存在"
                ).setIconColor(.red.opacity(0.5))
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
                        p.tabPlugins.first { $0.instanceLabel == tab }?.addDetailView()

                        if statusBarVisibility {
                            StatusBar()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: self.tab, onChangeOfTab)
        .onChange(of: self.columnVisibility, onChangeColumnVisibility)
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
                        ForEach(p.tabPlugins, id: \.instanceLabel) { plugin in
                            Text(plugin.instanceLabel).tag(plugin.instanceLabel)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }

            if g.project != nil, projectActionsVisibility {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    ForEach(toolbarTrailingViews, id: \.plugin.instanceLabel) { item in
                        item.view
                    }
                })
            }
        })
    }
}

// MARK: - Event

extension ContentView {
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
            os_log("\(self.t)🎯 Setting default tab to: \(d)")
            self.tab = d
        } else {
            // 如果没有提供默认标签页，使用Git标签页作为默认值
            os_log("\(self.t)🎯 No default tab provided, using GitPlugin.label: \(GitPlugin.label)")
            self.tab = GitPlugin.label
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
    }

    /// 处理项目变更事件
    func onProjectChange() {
    }

    /// 处理标签页变更事件
    /// 当用户切换标签页时，更新应用程序的当前标签页状态
    func onChangeOfTab() {
        app.setTab(tab)
    }

    /// 检查并处理导航分栏视图可见性变化
    func checkColumnVisibility(reason: String) {
        os_log("\(self.t)📺 onCheckColumnVisibility(\(reason))")
        if columnVisibility == .detailOnly {
            app.hideSidebar()
        } else {
            app.showSidebar(reason: "ContentView.onCheckColumnVisibility.TwoColumnMode")
        }
    }

    func onChangeColumnVisibility() {
        self.checkColumnVisibility(reason: "onChangeColumnVisibility")
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideProjectActions()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("Default - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
