import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// `ContentView` 是应用程序的主视图组件，负责整体布局和导航结构。
/// 它实现了 `SuperThread` 协议以便于线程管理（主线程和后台线程操作），
/// 以及 `SuperEvent` 协议以便于事件通知的发送和接收。
/// 
/// 该视图使用 `NavigationSplitView` 创建三栏布局：
/// - 侧边栏：显示项目列表
/// - 内容栏：显示当前选中的标签页
/// - 详情栏：显示当前选中标签页的详细内容
struct ContentView: View, SuperThread, SuperEvent {
    /// 应用程序状态管理器，提供全局应用状态和配置信息
    @EnvironmentObject var app: AppProvider
    /// Git 操作提供者，管理 Git 相关的状态和操作
    @EnvironmentObject var g: GitProvider
    /// 插件提供者，管理应用中的各种插件
    @EnvironmentObject var p: PluginProvider
    /// SwiftData 模型上下文，用于数据持久化
    @Environment(\.modelContext) private var modelContext

    /// 当前选中的分支
    @State var branch: Branch? = nil
    /// Git 日志信息
    @State var gitLog: String? = nil
    /// 当前消息文本
    @State var message: String = ""
    /// 当前选中的标签页，默认为 "Git"
    @State var tab: String = "Git"
    /// 导航分栏视图的可见性状态，默认只显示详情栏
    @State var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    /// 当前项目是否存在的标志
    @State var projectExists: Bool = true

    /// 获取所有标记为标签页的插件
    /// - Returns: 可作为标签页显示的插件数组
    var tabPlugins: [SuperPlugin] {
        p.plugins.filter { $0.isTab }
    }

    /// 构建视图层次结构
    /// - Returns: 组合后的视图
    var body: some View {
        Group {
            if projectExists {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    Sidebar()
                } content: {
                    if projectExists {
                        Tabs(tab: $tab)
                            .frame(idealWidth: 300)
                            .frame(minWidth: 50)
                            .onChange(of: tab, onChangeOfTab)
                    }
                } detail: {
                    VStack(spacing: 0) {
                        tabPlugins.first { $0.label == tab }?.addDetailView()

                        StatusBar()
                    }
                }
            } else {
                NoProject()
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: columnVisibility, onCheckColumnVisibility)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                ProjectPicker()
            }

            ToolbarItem(placement: .principal) {
                Picker("选择标签", selection: $tab) {
                    ForEach(tabPlugins, id: \.label) { plugin in
                        Text(plugin.label).tag(plugin.label)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }

            if let project = g.project, project.isExist() {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    BtnOpenTerminal(url: project.url)
                    BtnOpenXcode(url: project.url)
                    BtnOpen(url: project.url)
                    BtnOpenCursor(url: project.url)
                    BtnFinder(url: project.url)
                    BtnOpenRemote(message: $message, path: project.path)
                    BtnSync(message: $message, path: project.path)
                    if project.isGit {
                        Branches()
                    }
                })
            }
        })
    }
}

// MARK: - Event Handlers

/// 包含 ContentView 的事件处理方法的扩展
extension ContentView {
    /// 处理项目变更事件
    /// 当 GitProvider 中的项目发生变化时调用，检查项目是否存在并更新 UI
    func onProjectChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newProject = g.project {
                self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
            } else {
                self.projectExists = false
            }
        }
    }

    /// 视图出现时的处理逻辑
    /// 根据应用程序的侧边栏可见性设置来初始化导航分栏视图的状态，并设置当前标签页
    func onAppear() {
        if app.sidebarVisibility == true {
            self.columnVisibility = .all
        }

        if app.sidebarVisibility == false {
            self.columnVisibility = .doubleColumn
        }

        self.tab = app.currentTab
    }

    /// 检查并处理导航分栏视图可见性变化
    /// 当导航分栏视图的可见性状态发生变化时，在主线程上更新应用程序的侧边栏可见性状态
    func onCheckColumnVisibility() {
        self.main.async {
            if columnVisibility == .doubleColumn {
                app.hideSidebar()
            } else if columnVisibility == .automatic || columnVisibility == .all {
                app.showSidebar()
            }
        }
    }

    /// 处理标签页变更事件
    /// 当用户切换标签页时，更新应用程序的当前标签页状态
    func onChangeOfTab() {
        app.setTab(tab)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
