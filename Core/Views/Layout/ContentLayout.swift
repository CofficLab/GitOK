import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 应用程序的主视图组件。
struct ContentLayout: View, SuperThread, SuperEvent, SuperLog {
  /// emoji 标识符
  nonisolated static let emoji = "🍺"

  /// 是否启用详细日志输出
  nonisolated static let verbose = false
  /// 应用状态提供者环境对象
  @EnvironmentObject var app: AppProvider

  /// 插件提供者环境对象
  @EnvironmentObject var p: PluginProvider

  /// 当前选中的标签页
  private(set) var tab: String?

  /// 导航分栏视图的列可见性
  private(set) var columnVisibility: NavigationSplitViewVisibility?

  /// 状态栏是否可见
  private(set) var statusBarVisibility: Bool?

  /// 工具栏是否可见
  private(set) var toolbarVisibility: Bool?

  /// 项目操作按钮是否可见
  private(set) var projectActionsVisibility: Bool?

  /// 标签页选择器是否可见
  private(set) var tabPickerVisibility: Bool?

  /// 初始选中的标签页
  private(set) var initialTab: String?

  /// 初始化内容布局
  /// - Parameters:
  ///   - statusBarVisibility: 状态栏可见性
  ///   - initialColumnVisibility: 初始列可见性
  ///   - toolbarVisibility: 工具栏可见性
  ///   - projectActionsVisibility: 项目操作可见性
  ///   - tabPickerVisibility: 标签页选择器可见性
  ///   - initialTab: 初始标签页
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

  /// 视图主体
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: self.tabPickerVisibility,
      initialTab: self.initialTab
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
      tabPickerVisibility: false,
      initialTab: self.initialTab
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
      tabPickerVisibility: true,
      initialTab: self.initialTab
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
