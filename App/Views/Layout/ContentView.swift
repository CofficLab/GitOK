import MagicKit
import OSLog
import SwiftUI

/// 主内容视图，管理应用的整体布局和导航结构
struct ContentView: View, SuperLog {
  /// emoji 标识符
  nonisolated static let emoji = "📱"

  /// 是否启用详细日志输出
  nonisolated static let verbose = false

  @EnvironmentObject var app: AppProvider
  @EnvironmentObject var g: DataProvider
  @EnvironmentObject var p: PluginProvider

  /// 导航分栏视图的列可见性状态
  @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

  /// 当前选中的标签页
  @State private var tab: String = GitPlugin.label

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

  /// 缓存插件列表视图的插件和视图对
  private var pluginListViews: [(plugin: SuperPlugin, view: AnyView)] {
    p.plugins.compactMap { plugin in
      if let view = plugin.addListView(tab: tab, project: g.project) {
        return (plugin, view)
      }
      return nil
    }
  }

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
          p.tabPlugins.first { $0.instanceLabel == tab }?.addDetailView()

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
            p.tabPlugins.first { $0.instanceLabel == tab }?.addDetailView()

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
      // 如果没有提供默认标签页，使用Git标签页作为默认值
      if Self.verbose {
        os_log("\(self.t)No default tab provided, using GitPlugin.label: \(GitPlugin.label)")
      }
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
  func onChangeOfTab() {
    app.setTab(tab)
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
