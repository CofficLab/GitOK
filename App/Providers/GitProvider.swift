import AVKit
import Combine
import Foundation
import MagicCore
import MediaPlayer
import OSLog
import SwiftUI

class GitProvider: NSObject, ObservableObject, SuperLog {
    @Published private(set) var branches: [Branch] = []
    @Published var branch: Branch? = nil
    @Published var project: Project? = nil
    @Published private(set) var commit: GitCommit? = nil
    @Published private(set) var file: File? = nil
    @Published var projects: [Project] = []

    static let emoji = "🏠"
    private var cancellables = Set<AnyCancellable>()

    init(projects: [Project]) {
        self.projects = projects

        self.project = projects.first(where: {
            $0.path == AppConfig.projectPath
        })

        super.init()

        // 设置事件监听
        setupEventListeners()

        self.refreshBranches(reason: "GitProvider.Init")
    }

    /**
     * 设置事件监听器
     */
    private func setupEventListeners() {
        // 监听项目删除事件
        NotificationCenter.default.publisher(for: .gitProjectDeleted)
            .sink { [weak self] notification in
                self?.handleProjectDeleted(notification)
            }
            .store(in: &cancellables)

        // 监听分支变更事件
        NotificationCenter.default.publisher(for: .gitBranchChanged)
            .sink { [weak self] notification in
                self?.handleBranchChanged(notification)
            }
            .store(in: &cancellables)

        // 监听提交成功事件
        NotificationCenter.default.publisher(for: .gitCommitSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)

        // 监听推送成功事件
        NotificationCenter.default.publisher(for: .gitPushSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)

        // 监听拉取成功事件
        NotificationCenter.default.publisher(for: .gitPullSuccess)
            .sink { [weak self] notification in
                self?.handleGitOperationSuccess(notification)
            }
            .store(in: &cancellables)
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

    /**
     * 处理分支变更事件
     */
    private func handleBranchChanged(_ notification: Notification) {
        refreshBranches(reason: "Branch Changed Event")
    }

    /**
     * 处理Git操作成功事件
     */
    private func handleGitOperationSuccess(_ notification: Notification) {
        refreshBranches(reason: "Git Operation Success")
    }

    func setProject(_ p: Project?, reason: String) {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Project(\(reason))")
            os_log("  ➡️ \(p?.path ?? "")")
        }

        self.project = p
        AppConfig.setProjectPath(p?.path ?? "")
    }

    var currentBranch: Branch? {
        guard let project = project else {
            return nil
        }

        do {
            return try GitShell.getCurrentBranch(project.path)
        } catch _ {
            return nil
        }
    }

    func setFile(_ f: File?) {
        file = f
    }

    func setCommit(_ c: GitCommit?) {
        guard commit?.id != c?.id else { return }
        commit = c
    }

    func setBranch(_ branch: Branch?) throws {
        let verbose = false

        if verbose {
            os_log("\(self.t)Set Branch to \(branch?.name ?? "-")")
        }

        guard let project = project, let branch = branch else {
            return
        }

        if branch.name == currentBranch?.name {
            return
        }

        try GitShell.setBranch(branch, project.path, verbose: true)
    }

    func commit(_ message: String) {
        guard let project = self.project else { return }

        do {
            try GitShell.commit(project.path, commit: message)
        } catch {
            // 错误处理...
        }
    }

    func pull() {
        guard let project = self.project else { return }

        do {
            try GitShell.pull(project.path)
        } catch {
            // 错误处理...
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
            if repo.exists(path: url.path) {
                os_log("Project already exists: \(url.path)")
                return
            }
            
            // 通过仓库创建项目
            let newProject = try repo.create(url: url)
            
            // 添加到本地数组
            self.projects.append(newProject)
            
            // 如果当前没有选中项目，设置为新添加的项目
            if self.project == nil {
                self.setProject(newProject, reason: "Added first project")
            }
            
            os_log("Project added successfully: \(url.path)")
            
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

            // 发送删除通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .gitProjectDeleted,
                    object: self,
                    userInfo: ["path": path]
                )
            }

            os_log("Project deleted successfully: \(path)")

        } catch {
            os_log(.error, "Failed to delete project: \(error.localizedDescription)")
        }
    }

    func refreshBranches(reason: String) {
        let verbose = false

        guard let project = project else {
            return
        }

        if verbose {
            os_log("\(self.t)Refresh")
        }

        branches = (try? GitShell.getBranches(project.path)) ?? []
        branch = branches.first(where: {
            $0.name == self.currentBranch?.name
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
