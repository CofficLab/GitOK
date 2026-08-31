import KitGitOKCore
import KitGitOKSupport
import SwiftUI

/// 应用程序的主视图组件。
public struct ContentLayout: View, SuperThread, SuperEvent, SuperLog {
  /// emoji 标识符
  public nonisolated static let emoji = "🍺"

  /// 是否启用详细日志输出
  public nonisolated static let verbose = false

  /// 当前选中的标签页
  private(set) var tab: GitOKAppTab?

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
  private(set) var initialTab: GitOKAppTab?

  /// 初始化内容布局
  /// - Parameters:
  ///   - statusBarVisibility: 状态栏可见性
  ///   - initialColumnVisibility: 初始列可见性
  ///   - toolbarVisibility: 工具栏可见性
  ///   - projectActionsVisibility: 项目操作可见性
  ///   - tabPickerVisibility: 标签页选择器可见性
  ///   - initialTab: 初始标签页
  public init(
    statusBarVisibility: Bool? = nil,
    initialColumnVisibility: NavigationSplitViewVisibility? = nil,
    toolbarVisibility: Bool? = nil,
    projectActionsVisibility: Bool? = nil,
    tabPickerVisibility: Bool? = nil,
    initialTab: GitOKAppTab? = nil
  ) {
    self.statusBarVisibility = statusBarVisibility
    self.toolbarVisibility = toolbarVisibility
    self.projectActionsVisibility = projectActionsVisibility
    self.tabPickerVisibility = tabPickerVisibility
    self.columnVisibility = initialColumnVisibility
    self.initialTab = initialTab
  }

  /// 视图主体
  public var body: some View {
    ContentView(
      defaultStatusBarVisibility: statusBarVisibility,
      defaultTab: initialTab,
      defaultColumnVisibility: columnVisibility,
      defaultToolbarVisibility: toolbarVisibility,
      defaultProjectActionsVisibility: projectActionsVisibility,
      defaultTabVisibility: tabPickerVisibility
    )
  }
}

// MARK: - Modifier

extension ContentLayout {
  /// 隐藏侧边栏
  public func hideSidebar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: .detailOnly,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 显示侧边栏
  public func showSidebar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: .all,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 隐藏状态栏
  public func hideStatusBar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: false,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 显示状态栏
  public func showStatusBar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: true,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 隐藏工具栏
  public func hideToolbar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: false,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 显示工具栏
  public func showToolbar() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: true,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 隐藏项目操作按钮组
  public func hideProjectActions() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: false,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 显示项目操作按钮组
  public func showProjectActions() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: true,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: initialTab
    )
  }

  /// 隐藏标签选择器
  public func hideTabPicker() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: false,
      initialTab: initialTab
    )
  }

  /// 显示标签选择器
  public func showTabPicker() -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: true,
      initialTab: initialTab
    )
  }

  /// 设置初始标签页
  public func setInitialTab(_ tab: GitOKAppTab) -> ContentLayout {
    ContentLayout(
      statusBarVisibility: statusBarVisibility,
      initialColumnVisibility: columnVisibility,
      toolbarVisibility: toolbarVisibility,
      projectActionsVisibility: projectActionsVisibility,
      tabPickerVisibility: tabPickerVisibility,
      initialTab: tab
    )
  }
}
