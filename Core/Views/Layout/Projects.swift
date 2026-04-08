import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 项目列表视图
struct Projects: View, SuperLog {
  /// emoji 标识符
  nonisolated static let emoji = "🖥️"

  /// 是否启用详细日志输出
  nonisolated static let verbose = false

  /// 数据提供者环境对象
  @EnvironmentObject var data: DataProvider

  /// 当前选中的项目
  @State private var selection: Project? = nil

  /// 搜索文本
  @State private var searchText = ""

  /// 过滤后的项目列表
  private var filteredProjects: [Project] {
    if searchText.isEmpty {
      return data.projects
    }
    return data.projects.filter { project in
      project.title.localizedCaseInsensitiveContains(searchText)
    }
  }

  /// 视图主体
  var body: some View {
    VStack(spacing: 0) {
      // 搜索框 - 仅在项目数超过10个时显示
      if data.projects.count > 10 {
        AppSearchBar(text: $searchText, placeholder: "Search...")
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
      }

      // 项目列表
      List(selection: $selection) {
        ForEach(filteredProjects, id: \.self) { item in
          Text(item.title).tag(item as Project?)
            .contextMenu(
              ContextMenu(menuItems: {
                Button("置顶") {
                  pinItem(item)
                }

                if FileManager.default.fileExists(atPath: item.path) {
                  Button("在Finder中显示") {
                    let url = URL(fileURLWithPath: item.path)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                  }
                } else {
                  Button("项目已不存在") {
                    // 禁止点击
                  }
                  .disabled(true)
                }

                Divider()

                Button("删除") {
                  deleteItem(item)
                }
              }))
        }
        .onDelete(perform: deleteItems)
        .onMove(perform: moveItems)
      }
      .onChange(of: selection, { self.data.setProject(selection, reason: self.className) })
      .onAppear(perform: onAppear)
    }
  }
}

// MARK: - Action

extension Projects {
  /// 置顶项目到列表最上方
  /// - Parameter project: 要置顶的项目
  private func pinItem(_ project: Project) {
    // 查找当前项目的索引
    if let currentIndex = data.projects.firstIndex(of: project) {
      // 如果项目已经在最上方，不需要移动
      guard currentIndex > 0 else { return }

      withAnimation {
        // 将项目移动到列表最上方（索引0）
        let source = IndexSet([currentIndex])
        data.moveProjects(from: source, to: 0, using: data.repoManager.projectRepo)
      }

      if Self.verbose {
        os_log("\(self.t)Pinned project '\(project.title)' to top")
      }
    }
  }

  /// 删除单个项目
  /// - Parameter project: 要删除的项目
  private func deleteItem(_ project: Project) {
    withAnimation {
      self.data.deleteProject(project, using: data.repoManager.projectRepo)
    }
  }

  /// 删除多个项目
  /// - Parameter offsets: 要删除的项目索引集合
  private func deleteItems(offsets: IndexSet) {
    withAnimation {
      for index in offsets {
        try? self.data.repoManager.projectRepo.delete(data.projects[index])
      }
    }
  }

  /// 移动项目位置
  /// - Parameters:
  ///   - source: 源索引集合
  ///   - destination: 目标位置
  private func moveItems(from source: IndexSet, to destination: Int) {
    data.moveProjects(from: source, to: destination, using: data.repoManager.projectRepo)
  }
}

// MARK: - Event

extension Projects {
  /// 视图出现时的事件处理
  func onAppear() {
    if Self.verbose {
      os_log("\(self.t)onAppear, projects.count = \(data.projects.count)")
      os_log("\(self.t)Current Project: \(data.project?.path ?? "")")
    }
    self.selection = data.project
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
