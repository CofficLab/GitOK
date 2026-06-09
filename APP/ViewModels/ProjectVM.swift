import GitCoreKit
import GitOKCoreKit
import GitOKSupportKit
import OSLog
import SwiftUI

/// 当前项目状态管理
/// 维护当前选中的项目、文件、项目是否存在等状态
@MainActor
class ProjectVM: ObservableObject, SuperLog {
    nonisolated static let emoji = "🎯"
    nonisolated static let verbose = false

    // MARK: - Properties

    /// 当前选中的项目
    @Published private(set) var project: Project? = nil

    /// 当前选中的文件
    @Published private(set) var file: GitDiffFile? = nil

    /// 当前项目路径是否存在
    @Published private(set) var projectExists = true

    /// 当前项目是否已经确认是 Git 仓库。
    @Published private(set) var currentProjectIsGitRepository = false

    /// 当前项目 Git 仓库状态是否仍在后台检测中。
    @Published private(set) var isCheckingCurrentProjectGitRepository = false

    /// Git 仓库状态变化令牌，用于驱动依赖内部 State 的视图重算。
    @Published private(set) var projectGitRepositoryStateToken = 0

    /// 未推送提交数量
    @Published private(set) var unpushedCommitsCount: Int = 0

    /// 未推送提交的哈希集合（用于快速查询某个 commit 是否未推送）
    @Published private(set) var unpushedCommitHashes: Set<String> = []

    /// 项目是否 clean（无未提交的更改）
    @Published private(set) var isClean: Bool = true

    /// 当前分支相对 upstream 的 ahead/behind 状态
    @Published private(set) var aheadCount: Int = 0
    @Published private(set) var behindCount: Int = 0
    @Published private(set) var hasUpstream: Bool = false
    @Published private(set) var lastFetchedAt: Date? = nil

    /// 仓库管理器
    private let repoManager: RepoManager
    private var projectExistenceGeneration = 0
    private var gitRepositoryGeneration = 0
    private var gitRepositoryCheckTask: Task<Void, Never>?

    // MARK: - Initialization

    init(project: Project?, repoManager: RepoManager) {
        let start = Date()
        if Self.verbose {
            os_log("\(Self.t)🚀 Startup begin: ProjectVM.init project=\(project?.path ?? "nil")")
        }

        self.repoManager = repoManager
        self.project = project

        let existsStart = Date()
        self.checkIfProjectExists()
        if Self.verbose {
            os_log("\(Self.t)✅ Startup step: project exists=\(self.projectExists) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(existsStart)))s")
        }

        refreshCurrentProjectGitRepositoryState(reason: "init")

        if Self.verbose {
            os_log("\(Self.t)✅ Startup end: ProjectVM.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    // MARK: - Project Management

    /// 设置当前项目
    /// - Parameters:
    ///   - p: 要设置的项目
    ///   - reason: 设置原因
    func setProject(_ p: Project?, reason: String) {
        let start = Date()
        if Self.verbose {
            os_log("\(self.t)🎯 SetProject begin reason=\(reason) path=\(p?.path ?? "nil")")
            os_log("\(self.t)Set Project(\(reason)) \n ➡️ \(p?.path ?? "")")
        }

        self.project = p
        self.repoManager.stateRepo.setProjectPath(self.project?.path ?? "")
        resetProjectDerivedState()
        self.checkIfProjectExists()
        refreshCurrentProjectGitRepositoryState(reason: reason)

        if Self.verbose {
            os_log("\(self.t)✅ SetProject end reason=\(reason) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        }
    }

    /// 重新检测当前项目是否是 Git 仓库，并防止旧项目的异步结果回写到新项目。
    func refreshCurrentProjectGitRepositoryState(reason: String) {
        gitRepositoryGeneration += 1
        let generation = gitRepositoryGeneration
        gitRepositoryCheckTask?.cancel()

        guard let project else {
            currentProjectIsGitRepository = false
            isCheckingCurrentProjectGitRepository = false
            projectGitRepositoryStateToken += 1
            return
        }

        let path = project.path
        let repositoryURL = project.url
        let cachedValue = project.isGitRepo

        currentProjectIsGitRepository = cachedValue
        isCheckingCurrentProjectGitRepository = true
        projectGitRepositoryStateToken += 1

        let gitStart = Date()
        if Self.verbose {
            os_log("\(self.t)🚀 Git repository check scheduled reason=\(reason) path=\(path)")
        }

        gitRepositoryCheckTask = Task.detached(priority: .utility) {
            let isGitRepository = GitRepositoryCLI(repositoryURL: repositoryURL).isGitRepository()

            guard Task.isCancelled == false else { return }
            await MainActor.run {
                guard generation == self.gitRepositoryGeneration,
                      self.project?.path == path,
                      let currentProject = self.project else {
                    return
                }

                currentProject.updateIsGitRepoCacheSync(isGitRepository)
                self.currentProjectIsGitRepository = isGitRepository
                self.isCheckingCurrentProjectGitRepository = false
                self.projectGitRepositoryStateToken += 1
                self.gitRepositoryCheckTask = nil
                if Self.verbose {
                    os_log("\(self.t)✅ Git repository check finished isGit=\(isGitRepository) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(gitStart)))s path=\(path)")
                }
            }
        }
    }

    /// 设置当前选中的文件
    /// - Parameter f: 要设置的文件
    func setFile(_ f: GitDiffFile?) {
        if f == self.file { return }
        file = f
    }

    /// 更新未推送提交数量和哈希集合
    /// - Parameters:
    ///   - count: 未推送提交数量
    ///   - hashes: 未推送提交的哈希数组
    func updateUnpushedCommits(_ count: Int, hashes: [String], projectPath: String? = nil) {
        if let projectPath, project?.path != projectPath {
            return
        }
        self.unpushedCommitsCount = count
        self.unpushedCommitHashes = Set(hashes)
    }

    /// 检查指定提交是否未推送
    /// - Parameter commitHash: 提交的哈希值
    /// - Returns: 是否未推送
    func isCommitUnpushed(_ commitHash: String) -> Bool {
        return unpushedCommitHashes.contains(commitHash)
    }

    /// 更新项目的 clean 状态
    /// - Parameter isClean: 项目是否 clean
    func updateIsClean(_ isClean: Bool, projectPath: String? = nil) {
        if let projectPath, project?.path != projectPath {
            return
        }
        self.isClean = isClean
    }

    func updateRemoteTracking(_ status: GitOKRemoteTrackingStatus?, fetchedAt: Date?, projectPath: String? = nil) {
        if let projectPath, project?.path != projectPath {
            return
        }

        if let status {
            self.aheadCount = status.ahead
            self.behindCount = status.behind
            self.hasUpstream = status.hasUpstream
        } else {
            resetRemoteTrackingState()
        }

        if let fetchedAt {
            updateLastFetchedAt(fetchedAt)
        }
    }

    func updateLastFetchedAt(_ date: Date?) {
        self.lastFetchedAt = date
    }

    func resetRemoteTrackingState() {
        self.aheadCount = 0
        self.behindCount = 0
        self.hasUpstream = false
        self.lastFetchedAt = nil
    }

    private func resetProjectDerivedState() {
        isClean = true
        unpushedCommitsCount = 0
        unpushedCommitHashes = []
        resetRemoteTrackingState()
    }

    // MARK: - Private

    private func checkIfProjectExists() {
        projectExistenceGeneration += 1
        let generation = projectExistenceGeneration

        guard let newProject = self.project else {
            self.projectExists = false
            return
        }

        self.projectExists = true
        let path = newProject.path
        Task.detached(priority: .utility) {
            let exists = FileManager.default.fileExists(atPath: path)
            await MainActor.run {
                guard generation == self.projectExistenceGeneration,
                      self.project?.path == path else {
                    return
                }
                self.projectExists = exists
            }
        }
    }
}
