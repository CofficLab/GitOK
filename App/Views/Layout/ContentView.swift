import MagicCore
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
struct ContentView: View, SuperThread, SuperEvent, SuperLog {
    // MARK: - Public Properties

    static let emoji = "🍺"
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    /// 当前选中的分支
    @State var branch: Branch? = nil
    /// Git 日志信息
    @State var gitLog: String? = nil
    /// 当前消息文本
    @State var message: String = ""
    /// 当前选中的标签页，默认为 "Git"
    @State var tab: String = "Git"
    /// 导航分栏视图的可见性状态，默认只显示详情栏
    @State private(set) var columnVisibility: NavigationSplitViewVisibility = .all

    /// 当前布局模式：true为三栏模式，false为两栏模式
    @State var isThreeColumnMode: Bool = false

    // MARK: - Private Properties

    /// SwiftData 模型上下文，用于数据持久化
    @Environment(\.modelContext) private var modelContext
    /// 控制状态栏是否显示
    private var statusBarVisibility: Bool = true
    /// 控制工具栏是否显示
    private var toolbarVisibility: Bool = true
    /// 控制项目操作按钮组是否显示
    private var projectActionsVisibility: Bool = true
    /// 控制标签选择器是否显示
    private var tabPickerVisibility: Bool = true

    // MARK: - Initializers

    /// 初始化ContentView
    /// - Parameters:
    ///   - statusBarVisibility: 状态栏是否可见，默认为true
    ///   - initialColumnVisibility: 初始导航分栏视图的可见性状态，默认为.detailOnly
    ///   - toolbarVisibility: 工具栏是否可见，默认为true
    ///   - projectActionsVisibility: 项目操作按钮组是否可见，默认为true
    ///   - tabPickerVisibility: 标签选择器是否可见，默认为true
    init(statusBarVisibility: Bool = true, initialColumnVisibility: NavigationSplitViewVisibility = .detailOnly, toolbarVisibility: Bool = true, projectActionsVisibility: Bool = true, tabPickerVisibility: Bool = true) {
        self.statusBarVisibility = statusBarVisibility
        self.toolbarVisibility = toolbarVisibility
        self.projectActionsVisibility = projectActionsVisibility
        self.tabPickerVisibility = tabPickerVisibility
        self._columnVisibility = State(initialValue: initialColumnVisibility)
    }

    // MARK: - View Body

    /// 构建视图层次结构
    /// - Returns: 组合后的视图
    var body: some View {
        ContentLayout(
            tab: $tab,
            statusBarVisibility: statusBarVisibility
        )
        .onAppear(perform: onAppear)
        .onChange(of: tab, onChangeOfTab)
        .onChange(of: columnVisibility, onChangeColumnVisibility)
        .onChange(of: tab, updateLayoutMode)
        .onChange(of: g.project, updateLayoutMode)
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

// MARK: - Public Methods

/// 包含 ContentView 的公共方法的扩展
extension ContentView {
    /// 隐藏侧边栏
    /// - Returns: 一个新的ContentView实例，侧边栏被隐藏
    func hideSidebar() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: .doubleColumn,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示侧边栏
    /// - Returns: 一个新的ContentView实例，侧边栏被显示
    func showSidebar() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: .all,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏状态栏
    /// - Returns: 一个新的ContentView实例，状态栏被隐藏
    func hideStatusBar() -> ContentView {
        return ContentView(
            statusBarVisibility: false,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示状态栏
    /// - Returns: 一个新的ContentView实例，状态栏被显示
    func showStatusBar() -> ContentView {
        return ContentView(
            statusBarVisibility: true,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏工具栏
    /// - Returns: 一个新的ContentView实例，工具栏被隐藏
    func hideToolbar() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: false,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示工具栏
    /// - Returns: 一个新的ContentView实例，工具栏被显示
    func showToolbar() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: true,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏项目操作按钮组
    /// - Returns: 一个新的ContentView实例，项目操作按钮组被隐藏
    func hideProjectActions() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: false,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示项目操作按钮组
    /// - Returns: 一个新的ContentView实例，项目操作按钮组被显示
    func showProjectActions() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: true,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏标签选择器
    /// - Returns: 一个新的ContentView实例，标签选择器被隐藏
    func hideTabPicker() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: false
        )
    }

    /// 显示标签选择器
    /// - Returns: 一个新的ContentView实例，标签选择器被显示
    func showTabPicker() -> ContentView {
        return ContentView(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: true
        )
    }
}

// MARK: - Private Methods

/// 包含 ContentView 的私有事件处理方法的扩展
extension ContentView {
    /// 视图出现时的处理逻辑
    /// 只有在未明确设置导航分栏视图状态时，才根据应用程序的侧边栏可见性设置来初始化，并设置当前标签页
    func onAppear() {
        updateLayoutMode()

        os_log("\(self.t)📺 OnAppear \n ➡️ threeMode: \(self.isThreeColumnMode) \n ➡️ app.sidebarVisibility \(self.app.sidebarVisibility)")
        if app.sidebarVisibility == true {
            self.columnVisibility = .all
        } else {
            self.columnVisibility = isThreeColumnMode ? .doubleColumn : .detailOnly
        }

        self.tab = app.currentTab
    }

    /// 检查并处理导航分栏视图可见性变化
    /// 当导航分栏视图的可见性状态发生变化时，在主线程上更新应用程序的侧边栏可见性状态
    func checkColumnVisibility(reason: String) {
        os_log("\(self.t)📺 onCheckColumnVisibility(\(reason))")
        if isThreeColumnMode {
            if columnVisibility == .doubleColumn {
                app.hideSidebar()
            } else { app.showSidebar(reason: "ContentView.onCheckColumnVisibility.ThreeColumnMode")
            }
        } else {
            if columnVisibility == .detailOnly {
                app.hideSidebar()
            } else {
                app.showSidebar(reason: "ContentView.onCheckColumnVisibility.TwoColumnMode")
            }
        }
    }

    /// 处理标签页变更事件
    /// 当用户切换标签页时，更新应用程序的当前标签页状态
    func onChangeOfTab() {
        app.setTab(tab)
    }

    func onChangeColumnVisibility() {
        self.checkColumnVisibility(reason: "onChangeColumnVisibility")
    }

    /// 更新布局模式
    /// 根据当前标签页和项目状态决定使用两栏还是三栏布局
    func updateLayoutMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.isThreeColumnMode = !p.allListViewsEmpty(tab: tab, project: g.project)
        }
    }
}

#Preview("Default") {
    AppPreview()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}

#Preview("隐藏侧边栏") {
    RootView {
        ContentView().hideSidebar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("隐藏状态栏") {
    RootView {
        ContentView().hideStatusBar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("隐藏侧边栏和状态栏") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideStatusBar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("隐藏工具栏") {
    RootView {
        ContentView().hideToolbar()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("全部隐藏") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideStatusBar()
            .hideToolbar()
    }
    .frame(width: 600)
    .frame(height: 600)
}
