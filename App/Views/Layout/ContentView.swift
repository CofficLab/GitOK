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
                    title: "项目不存在",
                ).setIconColor(.red.opacity(0.5))
            } else {
                HSplitView {
                    VStack(spacing: 0) {
                        ForEach(p.plugins.filter { plugin in
                            plugin.addListView(tab: tab, project: g.project) != nil
                        }, id: \.instanceLabel) { plugin in
                            plugin.addListView(tab: tab, project: g.project)
                        }
                    }
                    .frame(idealWidth: 200)
                    .frame(minWidth: 120)
                    .frame(maxWidth: 200)

                    VStack(spacing: 0) {
                        p.tabPlugins.first { $0.instanceLabel == tab }?.addDetailView()

                        if statusBarVisibility {
                            StatusBar()
                        }
                    }
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
                ForEach(p.plugins, id: \.instanceLabel) { plugin in
                    plugin.addToolBarLeadingView()
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
                    ForEach(p.plugins, id: \.instanceLabel) { plugin in
                        plugin.addToolBarTrailingView()
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
            self.tab = d
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
