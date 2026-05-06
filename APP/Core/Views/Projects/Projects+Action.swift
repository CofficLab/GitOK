import Foundation
import SwiftUI
import OSLog

// MARK: - Action

extension Projects {
    /// 置顶项目到列表最上方
    /// - Parameter project: 要置顶的项目
    func pinItem(_ project: Project) {
        if let currentIndex = data.projects.firstIndex(of: project) {
            guard currentIndex > 0 else { return }

            withAnimation {
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
    func deleteItem(_ project: Project) {
        withAnimation {
            data.deleteProject(project, using: data.repoManager.projectRepo)
        }
    }

    /// 删除多个项目
    /// - Parameter offsets: 要删除的项目索引集合
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                try? data.repoManager.projectRepo.delete(data.projects[index])
            }
        }
    }

    /// 移动项目位置
    /// - Parameters:
    ///   - source: 源索引集合
    ///   - destination: 目标位置
    func moveItems(from source: IndexSet, to destination: Int) {
        data.moveProjects(from: source, to: destination, using: data.repoManager.projectRepo)
    }
}
