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
    private let verbose = false

    // MARK: - Properties

    /// 当前选中的项目
    @Published private(set) var project: Project? = nil

    /// 当前选中的文件
    @Published private(set) var file: GitDiffFile? = nil

    /// 当前项目路径是否存在
    @Published private(set) var projectExists = true

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

    // MARK: - Initialization

    init(project: Project?, repoManager: RepoManager) {
        let start = Date()
        os_log("\(Self.t)🚀 Startup begin: ProjectVM.init project=\(project?.path ?? "nil")")

        self.repoManager = repoManager
        self.project = project

        let existsStart = Date()
        self.checkIfProjectExists()
        os_log("\(Self.t)✅ Startup step: project exists=\(self.projectExists) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(existsStart)))s")

        if let project = project {
            let gitStart = Date()
            os_log("\(Self.t)🚀 Startup begin: Project.isGit path=\(project.path)")
            let isGit = project.isGit()
            os_log("\(Self.t)✅ Startup end: Project.isGit result=\(isGit) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(gitStart)))s")
            project.updateIsGitRepoCacheSync(isGit)
        }

        os_log("\(Self.t)✅ Startup end: ProjectVM.init elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
    }

    // MARK: - Project Management

    /// 设置当前项目
    /// - Parameters:
    ///   - p: 要设置的项目
    ///   - reason: 设置原因
    func setProject(_ p: Project?, reason: String) {
        let start = Date()
        os_log("\(self.t)🎯 SetProject begin reason=\(reason) path=\(p?.path ?? "nil")")

        if verbose {
            os_log("\(self.t)Set Project(\(reason)) \n ➡️ \(p?.path ?? "")")
        }

        self.project = p
        self.repoManager.stateRepo.setProjectPath(self.project?.path ?? "")
        self.checkIfProjectExists()

        if let project = p {
            let gitStart = Date()
            let isGit = project.isGit()
            os_log("\(self.t)✅ SetProject Project.isGit result=\(isGit) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(gitStart)))s")
            project.updateIsGitRepoCacheSync(isGit)

            Task.detached(priority: .userInitiated) {
                await project.updateIsGitRepoCache()
            }
        }

        os_log("\(self.t)✅ SetProject end reason=\(reason) elapsed=\(String(format: "%.3f", Date().timeIntervalSince(start)))s")
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
    func updateUnpushedCommits(_ count: Int, hashes: [String]) {
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
    func updateIsClean(_ isClean: Bool) {
        self.isClean = isClean
    }

    func updateRemoteTracking(_ status: GitOKRemoteTrackingStatus?, fetchedAt: Date?) {
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

    // MARK: - Private

    private func checkIfProjectExists() {
        if let newProject = self.project {
            self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
        } else {
            self.projectExists = false
        }
    }
}
