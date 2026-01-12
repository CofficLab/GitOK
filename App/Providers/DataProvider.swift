import AVKit
import LibGit2Swift
import MagicKit
import Combine
import Foundation
import MediaPlayer
import OSLog
import SwiftUI

@MainActor
class DataProvider: NSObject, ObservableObject, SuperLog {
    // MARK: - Properties
 
    @Published private(set) var project: Project? = nil
    @Published var projects: [Project] = []
    @Published var commit: GitCommit? = nil
    @Published private(set) var file: GitDiffFile? = nil
    @Published private(set) var projectExists = true
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

        self.project = projects.first(where: {
            $0.path == repoManager.stateRepo.projectPath
        })

        super.init()

        self.checkIfProjectExists()
    }
}

// MARK: - Project Management

extension DataProvider {
    /**
     * 设置当前项目
     * @param p 要设置的项目
     * @param reason 设置原因
     */
    func setProject(_ p: Project?, reason: String) {
        if verbose {
            os_log("\(self.t)Set Project(\(reason)) \n ➡️ \(p?.path ?? "")")
        }

        self.project = p
        self.repoManager.stateRepo.setProjectPath(self.project?.path ?? "")
        self.checkIfProjectExists()

        // 异步更新 isGitRepo 缓存
        if let project = p {
            Task.detached(priority: .userInitiated) {
                await project.updateIsGitRepoCache()
            }
        }
    }

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
            // 创建一个临时数组来重新排序
            var tempProjects = projects

            // 从原位置移除项目
            for index in source.sorted(by: >) {
                tempProjects.remove(at: index)
            }

            // 确保目标索引不会超出数组范围
            let safeDestination = min(destination, tempProjects.count)

            // 在目标位置插入项目
            for item in itemsToMove.reversed() {
                tempProjects.insert(item, at: safeDestination)
            }

            // 批量更新所有项目的order值
            for (index, project) in tempProjects.enumerated() {
                project.order = Int16(index)
            }

            // 通过repo保存更改
            try repo.save()

            // 更新本地projects数组
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
     */
    func addProject(url: URL, using repo: any ProjectRepoProtocol) {
        do {
            // 检查项目是否已存在
            if let existingProject = try repo.findByPath(url.path) {
                // 项目已存在，将其移动到第一个位置
                os_log("Project already exists, moving to first: \(url.path)")
                
                // 从当前位置移除
                if let index = self.projects.firstIndex(where: { $0.id == existingProject.id }) {
                    self.projects.remove(at: index)
                }
                
                // 设置order为-1，确保显示在最前面
                existingProject.order = -1
                try repo.update(existingProject)
                
                // 重新排序其他项目，确保order值连续
                try reorderProjectsAfterMovingToFirst(existingProject: existingProject, using: repo)
                
                // 插入到数组开头
                self.projects.insert(existingProject, at: 0)
                
                // 如果当前没有选中项目，设置为这个项目
                if self.project == nil {
                    self.setProject(existingProject, reason: "Moved existing project to first")
                }
                
                os_log("Existing project moved to first: \(url.path)")
                return
            }

            // 通过仓库创建新项目
            let newProject = try repo.create(url: url)

            // 添加到本地数组的开头，因为新项目的order为-1
            self.projects.insert(newProject, at: 0)

            // 如果当前没有选中项目，设置为新添加的项目
            if self.project == nil {
                self.setProject(newProject, reason: "Added first project")
            }

            os_log("New project added successfully: \(url.path)")

        } catch {
            os_log(.error, "Failed to add project: \(error.localizedDescription)")
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
            // 通过仓库删除项目
            try repo.delete(project)

            // 从本地数组中移除项目
            if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects.remove(at: index)
            }

            // 如果删除的是当前项目，切换到第一个可用项目
            if self.project?.id == project.id {
                self.project = self.projects.first
            }

            os_log("Project deleted successfully: \(path)")

        } catch {
            os_log(.error, "Failed to delete project: \(error.localizedDescription)")
        }
    }
    
    /**
     * 重新排序项目，确保order值连续
     * @param existingProject 被移动到第一位的项目
     * @param repo 项目仓库实例
     */
    private func reorderProjectsAfterMovingToFirst(existingProject: Project, using repo: any ProjectRepoProtocol) throws {
        // 获取除了被移动项目之外的其他项目
        let otherProjects = self.projects.filter { $0.id != existingProject.id }
        
        // 重新分配order值，从0开始
        for (index, project) in otherProjects.enumerated() {
            project.order = Int16(index)
            try repo.update(project)
        }
    }
}

// MARK: - Action

extension DataProvider {
    /**
     * 获取当前分支
     * @return 当前分支，如果获取失败则返回nil
     */
    private func updateCurrentBranch() {
        guard let project = project else {
            self.branch = nil
            return
        }

        do {
            self.branch = try project.getCurrentBranch()
        } catch _ {
            self.branch = nil
        }
    }
    
    private func checkIfProjectExists() {
        if let newProject = self.project {
            self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
        } else {
            self.projectExists = false
        }
    }

    /**
     * 设置当前选中的文件
     * @param f 要设置的文件
     */
    func setFile(_ f: GitDiffFile?) {
        assert(Thread.isMainThread, "setFile(_:) 必须在主线程调用，否则会导致线程安全问题！")
        if f == self.file { return }
        file = f
    }

    /**
     * 拉取远程代码
     */
    func pull() {
        guard let project = self.project else { return }

        do {
            try project.pull()
        } catch {
            // 错误处理...
        }
    }

    /**
     * 提交代码
     * @param message 提交信息
     */
    func commit(_ message: String) {
        guard let project = self.project else { return }

        do {
            try project.submit(message)
        } catch {
            // 错误处理...
        }
    }

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
    func setBranch(_ branch: GitBranch?) throws {
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

        // 检查目标分支是否已经是当前工作目录的分支，避免不必要的 checkout 操作
        if let currentBranch = try? project.getCurrentBranch(),
           currentBranch.name == branch.name {
            self.branch = branch
            return
        }

        try project.checkout(branch: branch)
        self.branch = branch
    }
}

// MARK: - Event Handling

extension DataProvider {
    /**
     * 处理Git操作成功事件
     */
    private func handleGitOperationSuccess(_ notification: Notification) {
    }

    /**
     * 处理Project变更事件
     */
    private func handleProjectChanged() {
    }

    /**
     * 处理项目删除事件
     */
    private func handleProjectDeleted(_ notification: Notification) {
        if let path = notification.userInfo?["path"] as? String {
            if self.project?.path == path {
                self.project = projects.first
                os_log("\(self.t)Project deleted, switched to first project")
            }
        }
    }
}

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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 1000)
        .frame(height: 1000)
}
