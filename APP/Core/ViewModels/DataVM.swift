import LibGit2Swift
import MagicKit
import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
class DataVM: NSObject, ObservableObject, SuperLog {
    // MARK: - Properties

    @Published var projects: [Project] = []
    @Published var commit: GitCommit? = nil
    @Published private(set) var branch: GitBranch? = nil
    @Published var activityStatus: String? = nil

    nonisolated static let emoji = "🏠"
    private let verbose = false
    var cancellables = Set<AnyCancellable>()
    let repoManager: RepoManager

    // MARK: - Initialization

    init(projects: [Project], repoManager: RepoManager) {
        self.projects = projects
        self.repoManager = repoManager

        super.init()
    }
}

// MARK: - Project Management

extension DataVM {
    /**
     * 移动项目并更新排序
     * @param source 源索引集合
     * @param destination 目标索引
     * @param repo 项目仓库实例
     */
    func moveProjects(from source: IndexSet, to destination: Int, using repo: any ProjectRepoProtocol) {
        let itemsToMove = source.map { self.projects[$0] }

        os_log("Moving items: \(itemsToMove.map { $0.title }) from \(source) to \(destination)")

        do {
            var tempProjects = projects

            for index in source.sorted(by: >) {
                tempProjects.remove(at: index)
            }

            let safeDestination = min(destination, tempProjects.count)

            for item in itemsToMove.reversed() {
                tempProjects.insert(item, at: safeDestination)
            }

            for (index, project) in tempProjects.enumerated() {
                project.order = Int16(index)
            }

            try repo.save()

            self.projects = tempProjects

            os_log("Successfully moved items and updated projects array.")

        } catch {
            os_log("Failed to move items: \(error.localizedDescription)")
        }
    }

    /**
     * 刷新项目列表
     * @param repo 项目仓库实例
     */
    func refreshProjects(using repo: any ProjectRepoProtocol) {
        do {
            self.projects = try repo.findAll(sortedBy: .ascending)
            os_log("Projects refreshed successfully, count: \(self.projects.count)")
        } catch {
            os_log(.error, "Failed to refresh projects: \(error.localizedDescription)")
        }
    }

    /**
     * 添加项目
     * @param url 项目路径URL
     * @param repo 项目仓库实例
     * @returns 添加或已存在的项目
     */
    @discardableResult
    func addProject(url: URL, using repo: any ProjectRepoProtocol) -> Project? {
        do {
            if let existingProject = try repo.findByPath(url.path) {
                os_log("Project already exists, moving to first: \(url.path)")

                if let index = self.projects.firstIndex(where: { $0.id == existingProject.id }) {
                    self.projects.remove(at: index)
                }

                existingProject.order = -1
                try repo.update(existingProject)

                try reorderProjectsAfterMovingToFirst(existingProject: existingProject, using: repo)

                self.projects.insert(existingProject, at: 0)

                os_log("Existing project moved to first: \(url.path)")
                return existingProject
            }

            let newProject = try repo.create(url: url)
            self.projects.insert(newProject, at: 0)
            os_log("New project added: \(url.path)")
            return newProject
        } catch {
            os_log(.error, "Failed to add project: \(error.localizedDescription)")
            return nil
        }
    }

    /**
     * 删除项目
     * @param project 要删除的项目
     * @param repo 项目仓库实例
     */
    func deleteProject(_ project: Project, using repo: any ProjectRepoProtocol) {
        let path = project.path

        do {
            try repo.delete(project)

            if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects.remove(at: index)
            }

            os_log("Project deleted successfully: \(path)")

        } catch {
            os_log(.error, "Failed to delete project: \(error.localizedDescription)")
        }
    }

    private func reorderProjectsAfterMovingToFirst(existingProject: Project, using repo: any ProjectRepoProtocol) throws {
        let otherProjects = self.projects.filter { $0.id != existingProject.id }

        for (index, project) in otherProjects.enumerated() {
            project.order = Int16(index)
            try repo.update(project)
        }
    }
}

// MARK: - Action

extension DataVM {
    /**
     * 设置当前选中的提交
     * @param c 要设置的提交
     */
    func setCommit(_ c: GitCommit?) {
        assert(Thread.isMainThread, "setCommit(_:) 必须在主线程调用，否则会导致线程安全问题！")
        guard commit?.id != c?.id else { return }
        commit = c
    }

    /**
     * 切换到指定分支
     * @param branch 要切换到的分支
     * @throws Git操作异常
     */
    func setBranch(_ branch: GitBranch?, project: Project?) throws {
        assert(Thread.isMainThread, "setBranch(_:) 必须在主线程调用，否则会导致线程安全问题！")
        if verbose {
            os_log("\(self.t)Set Branch to \(branch?.name ?? "-")")
        }

        guard let project = project, let branch = branch else {
            return
        }

        if branch == self.branch {
            return
        }

        if let currentBranch = try? project.getCurrentBranch(),
           currentBranch.name == branch.name {
            self.branch = branch
            return
        }

        try project.checkout(branch: branch)
        self.branch = branch
    }
}
