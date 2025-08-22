import MagicCore
import OSLog
import SwiftData
import SwiftUI

/// `应用程序的主视图组件。
struct ContentLayout: View, SuperThread, SuperEvent, SuperLog {
    static let emoji = "🍺"
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    private(set) var tab: String?
    private(set) var columnVisibility: NavigationSplitViewVisibility?
    private(set) var statusBarVisibility: Bool?
    private(set) var toolbarVisibility: Bool?
    private(set) var projectActionsVisibility: Bool?
    private(set) var tabPickerVisibility: Bool?
    private(set) var initialTab: String?

    init(
        statusBarVisibility: Bool? = nil,
        initialColumnVisibility: NavigationSplitViewVisibility? = nil,
        toolbarVisibility: Bool? = nil,
        projectActionsVisibility: Bool? = nil,
        tabPickerVisibility: Bool? = nil,
        initialTab: String? = nil
    ) {
        self.statusBarVisibility = statusBarVisibility
        self.toolbarVisibility = toolbarVisibility
        self.projectActionsVisibility = projectActionsVisibility
        self.tabPickerVisibility = tabPickerVisibility
        self.columnVisibility = initialColumnVisibility
        self.initialTab = initialTab
    }

    var body: some View {
        ContentView(
            defaultStatusBarVisibility: statusBarVisibility,
            defaultTab: initialTab,
            defaultColumnVisibility: columnVisibility,
            defaultProjectActionsVisibility: projectActionsVisibility,
            defaultTabVisibility: tabPickerVisibility
        )
    }
}

// MARK: - Modifier

extension ContentLayout {
    /// 隐藏侧边栏
    /// - Returns: 一个新的ContentView实例，侧边栏被隐藏
    func hideSidebar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: .detailOnly,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示侧边栏
    /// - Returns: 一个新的ContentView实例，侧边栏被显示
    func showSidebar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: .all,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏状态栏
    /// - Returns: 一个新的ContentView实例，状态栏被隐藏
    func hideStatusBar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: false,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示状态栏
    /// - Returns: 一个新的ContentView实例，状态栏被显示
    func showStatusBar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: true,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏工具栏
    /// - Returns: 一个新的ContentView实例，工具栏被隐藏
    func hideToolbar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: false,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示工具栏
    /// - Returns: 一个新的ContentView实例，工具栏被显示
    func showToolbar() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: true,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏项目操作按钮组
    /// - Returns: 一个新的ContentView实例，项目操作按钮组被隐藏
    func hideProjectActions() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: false,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 显示项目操作按钮组
    /// - Returns: 一个新的ContentView实例，项目操作按钮组被显示
    func showProjectActions() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: true,
            tabPickerVisibility: self.tabPickerVisibility
        )
    }

    /// 隐藏标签选择器
    /// - Returns: 一个新的ContentView实例，标签选择器被隐藏
    func hideTabPicker() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: false
        )
    }

    /// 显示标签选择器
    /// - Returns: 一个新的ContentView实例，标签选择器被显示
    func showTabPicker() -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: true
        )
    }

    /// 设置初始标签页
    /// - Parameter tab: 要设置的初始标签页名称
    /// - Returns: 一个新的ContentView实例，初始标签页被设置
    func setInitialTab(_ tab: String) -> ContentLayout {
        return ContentLayout(
            statusBarVisibility: self.statusBarVisibility,
            initialColumnVisibility: self.columnVisibility,
            toolbarVisibility: self.toolbarVisibility,
            projectActionsVisibility: self.projectActionsVisibility,
            tabPickerVisibility: self.tabPickerVisibility,
            initialTab: tab
        )
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
