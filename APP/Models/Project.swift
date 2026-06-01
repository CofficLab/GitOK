import Foundation
import GitOKCoreFeatures
import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 项目模型类
/// 表示一个Git项目的核心数据模型，包含项目的基本信息和操作方法
@Model
final class Project: SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "🌳"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    static var null = Project(URL(fileURLWithPath: ""))
    static var order = [
        SortDescriptor<Project>(\.order, order: .forward),
    ]
    static var orderReverse = [
        SortDescriptor<Project>(\.order, order: .reverse),
    ]
    var timestamp: Date
    var url: URL
    var order: Int16 = 0
    var commitStyleRawValue: String = CommitStyle.emoji.rawValue

    var title: String {
        url.lastPathComponent
    }

    var path: String {
        url.path
    }

    var commitStyle: CommitStyle {
        get { CommitStyle(rawValue: commitStyleRawValue) ?? .emoji }
        set { commitStyleRawValue = newValue.rawValue }
    }

    /// 缓存的 Git 仓库检查结果（不被持久化）
    @Transient private var _isGitRepo: Bool?

    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }

    // MARK: - Event Notification Helper

    /// 发送项目事件通知
    /// - Parameters:
    ///   - name: 通知名称
    ///   - operation: 操作类型
    ///   - success: 操作是否成功
    ///   - error: 错误信息（如果有）
    ///   - additionalInfo: 额外信息
    func postEvent(name: Notification.Name, operation: String, success: Bool = true, error: Error? = nil, additionalInfo: [String: Any]? = nil) {
        let eventInfo = ProjectEventInfo(
            project: self,
            operation: operation,
            success: success,
            error: error,
            additionalInfo: additionalInfo
        )

        // 确保在主线程发送通知，避免线程安全问题
        if Thread.isMainThread {
            NotificationCenter.default.post(
                name: name,
                object: self,
                userInfo: ["eventInfo": eventInfo]
            )
        } else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: name,
                    object: self,
                    userInfo: ["eventInfo": eventInfo]
                )
            }
        }

        if Self.verbose {
            os_log("\(self.t)🍋 Event posted: \(operation) - Success: \(success)")
        }
    }

    func postEvent(_ descriptor: ProjectGitOperationEventDescriptor) {
        postEvent(
            name: descriptor.notificationName,
            operation: descriptor.operation,
            success: descriptor.success,
            error: descriptor.error,
            additionalInfo: descriptor.additionalInfo
        )
    }

    func getCommits(_ reason: String) -> [GitCommit] {
        do {
            return (try gitCLI.commitList())
        } catch let error {
            os_log(.error, "\(self.t)GetCommits has error")
            os_log(.error, "\(error)")

            return []
        }
    }

    func isExist() -> Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
}

extension Project: Identifiable {
    var id: URL {
        self.url
    }
}

// MARK: - Git

extension Project {
    var isGitRepo: Bool {
        if path.isEmpty { return false }
        // 返回缓存值，避免重复检查
        return _isGitRepo ?? false
    }

    func isGit() -> Bool {
        return gitCLI.isGitRepository()
    }

    func isNotGit() -> Bool { !isGitRepo }

    func isNotGitAsync() async -> Bool {
        return isGit() == false
    }

    /**
        更新 isGitRepo 缓存（同步）

        直接设置缓存值，用于避免竞态条件
     */
    func updateIsGitRepoCacheSync(_ value: Bool) {
        self._isGitRepo = value
    }

    @MainActor
    private func applyIsGitRepoCache(_ value: Bool) {
        self._isGitRepo = value
    }

    /**
        更新 isGitRepo 缓存（异步）

        在后台检查 Git 仓库状态并更新缓存，避免阻塞主线程
     */
    func updateIsGitRepoCache() async {
        let result = isGit()
        await applyIsGitRepoCache(result)
    }

    func isClean(verbose: Bool = true) throws -> Bool {
        guard isGitRepo else {
            if verbose {
                os_log(.info, "\(self.t)🔄 Project is not a git repository")
            }

            return true
        }

        // 检查是否有未提交的已跟踪文件变更
        let hasUncommittedChanges = try gitCLI.hasUncommittedChanges(verbose: verbose)
        if hasUncommittedChanges {
            if verbose {
                os_log("\(self.t)🔄 Project has uncommitted changes")
            }
            return false
        }

        // 检查是否有未跟踪的文件
        let hasUntrackedFiles = try self.hasUntrackedFiles(verbose: verbose)
        if hasUntrackedFiles {
            if verbose {
                os_log(.info, "\(self.t)🔄 Project has untracked files")
            }
            return false
        }

        if verbose {
            os_log(.info, "\(self.t)🔄 Project is clean")
        }
        return true
    }

    /// 检查是否有未跟踪的文件
    /// - Parameter verbose: 是否启用详细日志
    /// - Returns: 如果有未跟踪文件返回 true，否则返回 false
    private func hasUntrackedFiles(verbose: Bool = false) throws -> Bool {
        // 获取 unstaged 文件列表（包含未跟踪文件）
        let unstagedFiles = try gitCLI.diffFileList(staged: false)

        // 检查是否有未跟踪文件（change type 为 "?"）
        let hasUntracked = unstagedFiles.contains { $0.changeType == "?" }

        if verbose && hasUntracked {
            let untrackedCount = unstagedFiles.filter { $0.changeType == "?" }.count
            os_log(.info, "\(self.t)🔄 Found \(untrackedCount) untracked files")
        }

        return hasUntracked
    }

    /// 检查项目是否没有未提交的更改
    /// - Returns: 如果没有未提交的更改返回 true，否则返回 false
    /// - Throws: Git 操作相关的错误
    func hasNoUncommittedChanges() throws -> Bool {
        return try gitCLI.hasUncommittedChanges(verbose: false) == false
    }
}

// MARK: - Branch

extension Project {
    /// 获取当前分支信息
    /// - Returns: 当前分支对象，如果获取失败返回 nil
    /// - Throws: Git 操作相关的错误
    func getCurrentBranch() throws -> GitBranch? {
        try gitCLI.currentBranchInfo()
    }

    /// 切换到指定分支
    /// - Parameter branch: 要切换到的分支
    /// - Throws: Git 操作相关的错误
    func checkout(branch: GitBranch) throws {
        do {
            try gitCLI.checkout(branch: branch.name)
            postEvent(
                name: .projectDidChangeBranch,
                operation: "checkout",
                additionalInfo: ["branchName": branch.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "checkout",
                success: false,
                error: error,
                additionalInfo: ["branchName": branch.name]
            )
            throw error
        }
    }

    func getBranches() throws -> [GitBranch] {
        try gitCLI.branchList()
    }

    /// 创建新分支并切换到该分支
    /// - Parameter branchName: 分支名称
    /// - Throws: Git操作异常
    func createBranch(_ branchName: String) throws {
        do {
            // 使用 Git 运行时创建并切换到新分支
            try gitCLI.checkoutNewBranch(named: branchName)

            postEvent(
                name: .projectDidChangeBranch,
                operation: "createBranch",
                additionalInfo: ["branchName": branchName]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "createBranch",
                success: false,
                error: error,
                additionalInfo: ["branchName": branchName]
            )
            throw error
        }
    }

    /// 删除本地分支。
    /// - Parameter branch: 要删除的本地分支。当前分支不能删除，未合并分支由 git 自身阻止。
    /// - Throws: Git 操作相关的错误
    func deleteLocalBranch(_ branch: GitBranch) throws {
        do {
            try gitCLI.deleteLocalBranch(named: branch.name)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "deleteLocalBranch",
                additionalInfo: ["branchName": branch.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "deleteLocalBranch",
                success: false,
                error: error,
                additionalInfo: ["branchName": branch.name]
            )
            throw error
        }
    }

    /// 重命名本地分支。
    /// - Parameters:
    ///   - branch: 要重命名的本地分支
    ///   - newName: 新分支名称
    /// - Throws: Git 操作相关的错误
    func renameBranch(_ branch: GitBranch, to newName: String) throws {
        do {
            try gitCLI.renameBranch(from: branch.name, to: newName)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "renameBranch",
                additionalInfo: ["oldBranchName": branch.name, "branchName": newName]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "renameBranch",
                success: false,
                error: error,
                additionalInfo: ["oldBranchName": branch.name, "branchName": newName]
            )
            throw error
        }
    }

    func remoteBranches(remote: String? = nil) throws -> [String] {
        try gitCLI.remoteBranches(remote: remote)
    }

    func setUpstream(localBranch: GitBranch, upstreamBranch: String) throws {
        do {
            try gitCLI.setUpstream(localBranch: localBranch.name, upstreamBranch: upstreamBranch)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "setBranchUpstream",
                additionalInfo: ["branchName": localBranch.name, "upstream": upstreamBranch]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "setBranchUpstream",
                success: false,
                error: error,
                additionalInfo: ["branchName": localBranch.name, "upstream": upstreamBranch]
            )
            throw error
        }
    }

    func unsetUpstream(localBranch: GitBranch) throws {
        do {
            try gitCLI.unsetUpstream(localBranch: localBranch.name)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "unsetBranchUpstream",
                additionalInfo: ["branchName": localBranch.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "unsetBranchUpstream",
                success: false,
                error: error,
                additionalInfo: ["branchName": localBranch.name]
            )
            throw error
        }
    }

    func deleteRemoteBranch(named branchName: String, remote: String = "origin") throws {
        do {
            try gitCLI.deleteRemoteBranch(named: branchName, remote: remote)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "deleteRemoteBranch",
                additionalInfo: ["branchName": branchName, "remote": remote]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "deleteRemoteBranch",
                success: false,
                error: error,
                additionalInfo: ["branchName": branchName, "remote": remote]
            )
            throw error
        }
    }

    func publishBranch(_ branch: GitBranch, remote: String = "origin") throws {
        do {
            try gitCLI.publishBranch(localBranch: branch.name, remote: remote)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "publishBranch",
                additionalInfo: ["branchName": branch.name, "remote": remote]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "publishBranch",
                success: false,
                error: error,
                additionalInfo: ["branchName": branch.name, "remote": remote]
            )
            throw error
        }
    }

    func compareBranches(base: GitBranch, head: GitBranch) throws -> GitOKBranchCompare {
        try gitCLI.compareBranches(base: base.name, head: head.name)
    }

    func rebaseStatus() throws -> GitRebaseStatus {
        try gitCLI.rebaseStatus()
    }

    func startRebase(branch: GitBranch, onto upstream: GitBranch) throws {
        do {
            try gitCLI.startRebase(branch: branch.name, onto: upstream.name)
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "startRebase",
                additionalInfo: ["branchName": branch.name, "upstream": upstream.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "startRebase",
                success: false,
                error: error,
                additionalInfo: ["branchName": branch.name, "upstream": upstream.name]
            )
            throw error
        }
    }

    func continueRebase() async throws {
        do {
            try gitCLI.continueRebase()
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "continueRebase"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "continueRebase",
                success: false,
                error: error
            )
            throw error
        }
    }

    func abortRebase() async throws {
        do {
            try gitCLI.abortRebase()
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "abortRebase"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "abortRebase",
                success: false,
                error: error
            )
            throw error
        }
    }

    func cherryPickStatus() throws -> GitCherryPickStatus {
        try gitCLI.cherryPickStatus()
    }

    func cherryPick(commits: [String], onto branch: GitBranch? = nil) throws {
        do {
            try gitCLI.cherryPick(commits: commits, onto: branch?.name)
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "cherryPick",
                additionalInfo: ["commitCount": commits.count, "branchName": branch?.name as Any]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "cherryPick",
                success: false,
                error: error,
                additionalInfo: ["commitCount": commits.count, "branchName": branch?.name as Any]
            )
            throw error
        }
    }

    func continueCherryPick() async throws {
        do {
            try gitCLI.continueCherryPick()
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "continueCherryPick"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "continueCherryPick",
                success: false,
                error: error
            )
            throw error
        }
    }

    func abortCherryPick() async throws {
        do {
            try gitCLI.abortCherryPick()
            postEvent(
                name: .projectGitHeadDidChange,
                operation: "abortCherryPick"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "abortCherryPick",
                success: false,
                error: error
            )
            throw error
        }
    }

    /// 合并分支
    /// - Parameter branchName: 要合并的分支名称
    /// - Throws: Git操作异常
    /// 合并分支：将来源分支合并到目标分支
    /// - Parameters:
    ///   - fromBranch: 来源分支
    ///   - toBranch: 目标分支
    /// - Throws: Git 错误
    func mergeBranches(fromBranch: GitBranch, toBranch: GitBranch) throws {
        do {
            // 切换到目标分支
            try gitCLI.checkout(branch: toBranch.name)
            postEvent(
                name: .projectDidChangeBranch,
                operation: "checkout",
                additionalInfo: ["branchName": toBranch.name, "reason": "merge_setup"]
            )

            // 执行合并
            try gitCLI.merge(branchName: fromBranch.name, verbose: false)
            postEvent(
                name: .projectDidMerge,
                operation: "merge",
                additionalInfo: ["fromBranch": fromBranch.name, "toBranch": toBranch.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "merge",
                success: false,
                error: error,
                additionalInfo: ["fromBranch": fromBranch.name, "toBranch": toBranch.name]
            )
            throw error
        }
    }

    /// 合并分支（兼容旧接口）
    /// - Parameter branchName: 要合并的分支名称
    /// - Throws: Git 错误
    func merge(branchName: String) throws {
        do {
            try gitCLI.merge(branchName: branchName, verbose: false)

            postEvent(
                name: .projectDidMerge,
                operation: "merge",
                additionalInfo: ["branchName": branchName]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "merge",
                success: false,
                error: error,
                additionalInfo: ["branchName": branchName]
            )
            throw error
        }
    }
}

// MARK: - Add

extension Project {
    private var gitCLI: GitRepositoryCLI {
        GitRepositoryCLI(repositoryURL: url)
    }

    /// 将所有更改的文件添加到Git暂存区
    /// - Throws: Git 操作相关的错误
    func addAll() throws {
        do {
            try gitCLI.addAllFiles()
            postEvent(
                name: .projectDidAddFiles,
                operation: "addAll"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "addAll",
                success: false,
                error: error
            )
            throw error
        }
    }

    /// 将指定文件添加到 Git 暂存区
    /// - Parameter filePaths: 相对于仓库根目录的文件路径
    /// - Throws: Git 操作相关的错误
    func addFiles(_ filePaths: [String]) throws {
        do {
            try gitCLI.addFiles(filePaths)
            postEvent(
                name: .projectDidAddFiles,
                operation: "addFiles",
                additionalInfo: ["files": filePaths]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "addFiles",
                success: false,
                error: error,
                additionalInfo: ["files": filePaths]
            )
            throw error
        }
    }

    func unstageFiles(_ filePaths: [String]) throws {
        do {
            try gitCLI.unstageFiles(filePaths)
            postEvent(
                name: .projectDidAddFiles,
                operation: "unstageFiles",
                additionalInfo: ["files": filePaths]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "unstageFiles",
                success: false,
                error: error,
                additionalInfo: ["files": filePaths]
            )
            throw error
        }
    }

    func fileDiff(_ filePath: String, staged: Bool, ignoreWhitespace: Bool = false) throws -> String {
        try gitCLI.fileDiff(filePath, staged: staged, ignoreWhitespace: ignoreWhitespace)
    }

    func applyPatch(_ patch: String, mode: GitOKPatchApplyMode, filePath: String) throws {
        do {
            try gitCLI.applyPatch(patch, mode: mode)
            postEvent(
                name: .projectDidAddFiles,
                operation: mode == .stage ? "stagePatch" : "unstagePatch",
                additionalInfo: ["filePath": filePath]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: mode == .stage ? "stagePatch" : "unstagePatch",
                success: false,
                error: error,
                additionalInfo: ["filePath": filePath]
            )
            throw error
        }
    }

    func statusEntries() throws -> [GitStatusEntry] {
        try gitCLI.statusEntries()
    }

    func hasStagedChanges() throws -> Bool {
        try statusEntries().contains { entry in
            entry.indexStatus != " " && entry.indexStatus != "?"
        }
    }
}

// MARK: - User

extension Project {
    func getUserName() throws -> String {
        try gitCLI.configValue(key: "user.name")
    }

    func getUserEmail() throws -> String {
        try gitCLI.configValue(key: "user.email")
    }

    /// 设置项目的Git用户信息（仅针对当前项目）
    /// - Parameters:
    ///   - userName: 用户名
    ///   - userEmail: 用户邮箱
    /// - Throws: Git操作异常
    func setUserConfig(name userName: String, email userEmail: String) throws {
        do {
            try gitCLI.setUserConfig(name: userName, email: userEmail)
            postEvent(
                name: .projectDidUpdateUserInfo,
                operation: "setUserConfig",
                additionalInfo: ["userName": userName, "userEmail": userEmail]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "setUserConfig",
                success: false,
                error: error,
                additionalInfo: ["userName": userName, "userEmail": userEmail]
            )
            throw error
        }
    }

    /// 获取项目的Git用户配置
    /// - Returns: 用户配置信息（用户名，邮箱）
    /// - Throws: Git操作异常
    func getUserConfig() throws -> (name: String, email: String) {
        try gitCLI.userConfig()
    }

    /// 批量设置用户信息
    /// - Parameters:
    ///   - userName: 用户名
    ///   - userEmail: 用户邮箱
    /// - Throws: Git操作异常
    func setUserInfo(userName: String, userEmail: String) throws {
        try setUserConfig(name: userName, email: userEmail)
    }
}

// MARK: - Commit

extension Project {
    /// 获取未推送的提交（本地领先远程的提交）
    /// 使用 Git 运行时原生实现
    func getUnPushedCommits() async throws -> [GitCommit] {
        return try gitCLI.unpushedCommits()
    }

    /// 获取未拉取的提交（远程领先本地的提交）
    /// 注意：当前返回空数组，因为当前 Git 运行时无法直接访问远程提交
    /// 但可以通过 getUnPulledCount() 获取数量
    func getUnPulledCommits() async throws -> [GitCommit] {
        // 由于当前 Git 运行时无法直接访问远程提交，暂时返回空数组
        return []
    }

    /// 获取未拉取的提交数量（远程领先本地的提交数量）
    func getUnPulledCount() throws -> Int {
        return try gitCLI.unpulledCount()
    }

    func submit(_ message: String) throws {
        assert(Thread.isMainThread, "setCommit(_:) 必须在主线程调用，否则会导致线程安全问题！")
        do {
            _ = try gitCLI.createCommit(message: message)
            postEvent(
                name: .projectDidCommit,
                operation: "commit",
                additionalInfo: ["message": message]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "commit",
                success: false,
                error: error,
                additionalInfo: ["message": message]
            )
            throw error
        }
    }

    func getCommitsWithPagination(_ page: Int, limit: Int) throws -> [GitCommit] {
        return try gitCLI.commitList(page: page, size: limit)
    }

    func getCommitGraphWithPagination(_ page: Int, limit: Int) throws -> [GitCommit] {
        return try gitCLI.commitGraphList(page: page, size: limit)
    }

    /// 撤销指定的提交（仅限未推送的 HEAD commit）
    /// 原理：执行 git reset --mixed <parentHash>，将提交的文件变更保留在工作区（未暂存状态）
    /// - Parameter commit: 要撤销的提交
    /// - Throws: Git 操作异常
    func undoCommit(_ commit: GitCommit) throws {
        do {
            if commit.parentHashes.isEmpty {
                // 初始提交无法通过 reset 撤销，需要特殊处理
                throw NSError(
                    domain: "GitOK",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "暂不支持撤销初始提交"]
                )
            }

            // 使用 mixed reset：HEAD 回退到 parent，文件变更保留在工作区
            let parentHash = commit.parentHashes[0]
            try gitCLI.reset(to: parentHash, mode: "mixed")

            postEvent(
                name: .projectDidCommit,
                operation: "undoCommit",
                additionalInfo: ["commitHash": commit.hash, "parentHash": parentHash]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "undoCommit",
                success: false,
                error: error,
                additionalInfo: ["commitHash": commit.hash]
            )
            throw error
        }
    }

    func revertCommit(_ commit: GitCommit) throws {
        do {
            try gitCLI.revertCommit(commit.hash)
            postEvent(
                name: .projectDidCommit,
                operation: "revertCommit",
                additionalInfo: ["commitHash": commit.hash]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "revertCommit",
                success: false,
                error: error,
                additionalInfo: ["commitHash": commit.hash]
            )
            throw error
        }
    }

    func reset(to commit: GitCommit, mode: GitOKResetMode) throws {
        do {
            try gitCLI.reset(to: commit.hash, mode: mode)
            postEvent(
                name: .projectDidCommit,
                operation: "reset\(mode.rawValue.capitalized)",
                additionalInfo: ["commitHash": commit.hash]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "reset\(mode.rawValue.capitalized)",
                success: false,
                error: error,
                additionalInfo: ["commitHash": commit.hash]
            )
            throw error
        }
    }

    func squashLastCommits(count: Int, message: String) throws {
        do {
            try gitCLI.squashLastCommits(count: count, message: message)
            postEvent(
                name: .projectDidCommit,
                operation: "squashCommits",
                additionalInfo: ["commitCount": count]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "squashCommits",
                success: false,
                error: error,
                additionalInfo: ["commitCount": count]
            )
            throw error
        }
    }
}

// MARK: - File

extension Project {
    func fileContent(at: String, file: String) throws -> String {
        try gitCLI.fileContent(atCommit: at, file: file)
    }

    func fileContentChange(at commit: String, file: String) throws -> (before: String?, after: String?) {
        try gitCLI.fileContentChange(atCommit: commit, file: file)
    }

    func uncommittedFileContentChange(file: String) throws -> (before: String?, after: String?) {
        try gitCLI.uncommittedFileContentChange(for: file)
    }

    /// 获取指定提交中文件的 diff 字符串
    func fileDiff(at commit: String, file: String, ignoreWhitespace: Bool = false) throws -> String {
        return try gitCLI.fileDiff(atCommit: commit, for: file)
    }

    /// 获取未提交文件的 diff 字符串
    func uncommittedFileDiff(file: String, ignoreWhitespace: Bool = false) throws -> String {
        return try gitCLI.uncommittedFileDiff(for: file, ignoreWhitespace: ignoreWhitespace)
    }

    /// 获取指定提交中文件的原始二进制数据（支持图片等二进制文件）
    func fileData(at commit: String, file: String) throws -> Data {
        try gitCLI.fileData(atCommit: commit, file: file)
    }

    /// 获取 HEAD 提交的哈希值
    func headCommitHash() -> String? {
        guard let commits = try? gitCLI.commitList(),
              let first = commits.first else {
            return nil
        }
        return first.hash
    }

    /// 获取指定提交中文件的 diff 字符串
    /// - Parameters:
    ///   - atCommit: 提交哈希
    ///   - verbose: 是否启用详细日志输出
    /// - Returns: 文件列表
    /// - Throws: Git操作异常
    func changedFilesDetail(in atCommit: String, verbose: Bool = false) async throws -> [GitDiffFile] {
        if verbose {
            os_log(.info, "\(self.t)🍋 changedFilesDetail(in: \(atCommit))")
        }

        // 使用 Git 运行时获取指定 commit 修改的文件列表，并按文件路径排序
        return try gitCLI.commitDiffFiles(atCommit: atCommit)
            .sorted { $0.file < $1.file }
    }

    func untrackedFiles() async throws -> [GitDiffFile] {
        // Get both staged and unstaged changes to show all uncommitted changes
        let stagedFiles = try gitCLI.diffFileList(staged: true)
        let unstagedFiles = try gitCLI.diffFileList(staged: false)

        // Merge the two lists, removing duplicates by file path
        var mergedFiles: [String: GitDiffFile] = [:]
        for file in stagedFiles + unstagedFiles {
            // If the same file appears in both, prefer the staged version
            if mergedFiles[file.file] == nil {
                mergedFiles[file.file] = file
            }
        }

        // 按文件路径排序，确保顺序稳定
        return Array(mergedFiles.values).sorted { $0.file < $1.file }
    }

    func stagedDiffFileList() async throws -> [GitDiffFile] {
        return try gitCLI.diffFileList(staged: true)
            .sorted { $0.file < $1.file }
    }

    func unstagedDiffFileList() async throws -> [GitDiffFile] {
        return try gitCLI.diffFileList(staged: false)
            .sorted { $0.file < $1.file }
    }

    /// 丢弃文件的更改（恢复到 HEAD 版本）
    /// - Parameter filePath: 文件路径（相对于仓库根目录）
    /// - Throws: Git操作异常
    func discardFileChanges(_ filePath: String) throws {
        do {
            try gitCLI.discardFileChanges(filePath)

            postEvent(
                name: .projectDidCommit,
                operation: "discardFileChanges",
                additionalInfo: ["filePath": filePath]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "discardFileChanges",
                success: false,
                error: error,
                additionalInfo: ["filePath": filePath]
            )
            throw error
        }
    }

    /// 丢弃所有工作区更改
    /// 将工作区重置为 HEAD 状态，丢弃所有未提交的更改（包括已暂存和未暂存的）
    /// - Throws: Git 操作异常
    func discardAllChanges() throws {
        do {
            try gitCLI.discardAllChanges()

            postEvent(
                name: .projectDidCommit,
                operation: "discardAllChanges"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "discardAllChanges",
                success: false,
                error: error
            )
            throw error
        }
    }

    /// 保存当前工作区更改到stash
    /// - Parameter message: stash的描述信息，可选
    /// - Throws: Git操作异常
    func stashSave(message: String? = nil) throws {
        do {
            try gitCLI.stashSave(message: message)
            postEvent(.stashSaveSuccess(message: message))
        } catch {
            postEvent(.stashSaveFailure(message: message, error: error))
            throw error
        }
    }

    /// 获取stash列表
    /// - Returns: stash列表，包含索引、消息、分支、时间和预览信息
    /// - Throws: Git操作异常
    func stashList() throws -> [GitStashEntry] {
        try gitCLI.stashList()
    }

    /// 应用指定的stash（保留stash）
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashApply(index: Int) throws {
        do {
            try gitCLI.stashApply(index: index)
            postEvent(.stashApplySuccess(index: index))
        } catch {
            postEvent(.stashApplyFailure(index: index, error: error))
            throw error
        }
    }

    /// 弹出指定的stash（应用并删除stash）
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashPop(index: Int) throws {
        do {
            try gitCLI.stashPop(index: index)
            postEvent(.stashPopSuccess(index: index))
        } catch {
            postEvent(.stashPopFailure(index: index, error: error))
            throw error
        }
    }

    /// 删除指定的stash
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashDrop(index: Int) throws {
        do {
            try gitCLI.stashDrop(index: index)
            postEvent(.stashDropSuccess(index: index))
        } catch {
            postEvent(.stashDropFailure(index: index, error: error))
            throw error
        }
    }

    /// 基于指定 stash 创建分支并恢复改动。
    /// - Parameters:
    ///   - name: 新分支名称
    ///   - index: stash 的索引
    /// - Throws: Git 操作异常
    func stashBranch(name: String, index: Int) throws {
        try gitCLI.stashBranch(name: name, index: index)
        postEvent(.stashPopSuccess(index: index))
    }

    /// 获取当前正在合并的分支名
    /// - Returns: 当前合并来源分支名，如果无法解析则返回 nil
    func getCurrentMergeBranchName() throws -> String? {
        try gitCLI.getCurrentMergeBranchName()
    }

    /// 获取合并冲突文件列表
    /// - Returns: 冲突文件路径列表
    /// - Throws: Git操作异常
    func getMergeConflictFiles() async throws -> [String] {
        try gitCLI.getMergeConflictFiles()
    }

    /// 检查是否正在合并状态
    /// - Returns: 如果正在合并返回true
    /// - Throws: Git操作异常
    func isMerging() async throws -> Bool {
        try gitCLI.isMerging()
    }

    /// 检查是否有合并冲突
    /// - Returns: 如果有冲突返回true
    /// - Throws: Git操作异常
    func hasMergeConflicts() async throws -> Bool {
        try await getMergeConflictFiles().isEmpty == false
    }

    func mergeFileContent(path: String, version: GitMergeFileVersion) throws -> String {
        try gitCLI.mergeFileContent(path: path, version: version)
    }

    func mergeFileDiff(path: String) throws -> String {
        try gitCLI.mergeFileDiff(path: path)
    }

    func checkoutMergeFileVersion(path: String, version: GitMergeFileVersion) throws {
        try gitCLI.checkoutMergeFileVersion(path: path, version: version)
        postEvent(
            name: .projectGitIndexDidChange,
            operation: "checkoutMergeFileVersion",
            additionalInfo: ["filePath": path, "version": version.rawValue]
        )
    }

    /// 中止合并操作
    /// - Throws: Git操作异常
    func abortMerge() async throws {
        do {
            try gitCLI.abortMerge()
            postEvent(.abortMergeSuccess())
        } catch {
            postEvent(.abortMergeFailure(error: error))
            throw error
        }
    }

    /// 继续合并操作（解决冲突后）
    /// - Parameter branchName: 要合并的分支名
    /// - Throws: Git操作异常
    func continueMerge(branchName: String) async throws {
        do {
            try gitCLI.continueMerge()
            postEvent(.continueMergeSuccess(branchName: branchName))
        } catch {
            postEvent(.continueMergeFailure(branchName: branchName, error: error))
            throw error
        }
    }

    /// 获取项目的README.md文件内容
    /// - Returns: README.md文件的内容，如果文件不存在则抛出异常
    /// - Throws: 文件不存在或读取错误
    func getReadmeContent() async throws -> String {
        try ProjectDocumentResolver.readReadmeContent(in: URL(fileURLWithPath: self.path))
    }

    /// 获取项目根目录的 .gitignore 内容
    /// - Returns: .gitignore 文件内容，如果不存在则抛出异常
    func getGitignoreContent() async throws -> String {
        try ProjectDocumentResolver.readGitignoreContent(in: URL(fileURLWithPath: self.path))
    }

    /// 获取 LICENSE 内容（支持多种常见文件名）
    func getLicenseContent() async throws -> String {
        try ProjectDocumentResolver.readLicenseContent(in: URL(fileURLWithPath: self.path))
    }

    /// 写入/创建 LICENSE 内容，使用 `LICENSE` 文件名
    func saveLicenseContent(_ content: String) async throws {
        let licenseURL = URL(fileURLWithPath: self.path).appendingPathComponent("LICENSE")
        try content.write(to: licenseURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Remote

extension Project {
    /// 推送当前分支到远程仓库
    /// - Throws: Git 操作相关的错误
    func push() throws {
        do {
            // 获取当前分支信息
            let currentBranch = try gitCLI.currentBranchName() ?? ""
            os_log(.default, "📍 Current branch: \(currentBranch)")

            try gitCLI.push()

            postEvent(
                name: .projectDidPush,
                operation: "push"
            )
        } catch {
            let pushError: Error
            if let message = GitOperationError.pushNeedsFetchMessage(from: error) {
                pushError = GitOperationError.pushNeedsFetch(message: message)
            } else {
                pushError = error
            }

            os_log(.default, "❌ Push failed: \(pushError.localizedDescription)")
            postEvent(
                name: .projectOperationDidFail,
                operation: "push",
                success: false,
                error: pushError
            )
            throw pushError
        }
    }

    func fetch(remote: String = "origin") throws {
        do {
            try gitCLI.fetch(remote: remote)

            postEvent(
                name: .projectDidFetch,
                operation: "fetch",
                additionalInfo: ["remote": remote]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "fetch",
                success: false,
                error: error,
                additionalInfo: ["remote": remote]
            )
            throw error
        }
    }

    func aheadBehind() throws -> GitOKAheadBehind {
        try gitCLI.aheadBehind()
    }

    func pull() throws {
        do {
            try gitCLI.pull()

            postEvent(
                name: .projectDidPull,
                operation: "pull"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "pull",
                success: false,
                error: error
            )
            throw error
        }
    }

    func sync() throws {
        do {
            try self.fetch()
            let trackingState = try self.aheadBehind()

            if trackingState.hasUpstream,
               trackingState.ahead > 0,
               trackingState.behind > 0 {
                throw GitOperationError.syncNeedsUserDecision(
                    ahead: trackingState.ahead,
                    behind: trackingState.behind
                )
            }

            if trackingState.hasUpstream, trackingState.behind > 0 {
                try self.pull()
            }

            if trackingState.hasUpstream == false || trackingState.ahead > 0 {
                try self.push()
            }

            postEvent(
                name: .projectDidSync,
                operation: "sync"
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "sync",
                success: false,
                error: error
            )
            throw error
        }
    }

    func remoteList() throws -> [GitRemote] {
        try gitCLI.remoteList()
    }

    func addRemote(name: String, url: String) throws {
        do {
            try gitCLI.addRemote(name: name, url: url)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "addRemote",
                additionalInfo: ["remote": name, "url": url]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "addRemote",
                success: false,
                error: error,
                additionalInfo: ["remote": name, "url": url]
            )
            throw error
        }
    }

    func updateRemote(originalName: String, newName: String, newURL: String) throws {
        do {
            try gitCLI.updateRemote(originalName: originalName, newName: newName, newURL: newURL)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "updateRemote",
                additionalInfo: ["oldRemote": originalName, "remote": newName, "url": newURL]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "updateRemote",
                success: false,
                error: error,
                additionalInfo: ["oldRemote": originalName, "remote": newName, "url": newURL]
            )
            throw error
        }
    }

    func removeRemote(name: String) throws {
        do {
            try gitCLI.removeRemote(name: name)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "removeRemote",
                additionalInfo: ["remote": name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "removeRemote",
                success: false,
                error: error,
                additionalInfo: ["remote": name]
            )
            throw error
        }
    }
}

// MARK: - Tag

extension Project {
    func tags(for commit: String) throws -> [String] {
        try gitCLI.tags(for: commit)
    }

    func getTags(commit: String) throws -> [String] {
        try tags(for: commit)
    }

    func createLightweightTag(named tagName: String, commitHash: String) throws {
        do {
            try gitCLI.createLightweightTag(named: tagName, commitHash: commitHash)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "createLightweightTag",
                additionalInfo: ["tagName": tagName, "commitHash": commitHash]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "createLightweightTag",
                success: false,
                error: error,
                additionalInfo: ["tagName": tagName, "commitHash": commitHash]
            )
            throw error
        }
    }

    func createAnnotatedTag(named tagName: String, commitHash: String, message: String) throws {
        do {
            try gitCLI.createAnnotatedTag(named: tagName, commitHash: commitHash, message: message)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "createAnnotatedTag",
                additionalInfo: ["tagName": tagName, "commitHash": commitHash]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "createAnnotatedTag",
                success: false,
                error: error,
                additionalInfo: ["tagName": tagName, "commitHash": commitHash]
            )
            throw error
        }
    }

    func deleteLocalTag(named tagName: String) throws {
        do {
            try gitCLI.deleteLocalTag(named: tagName)
            postEvent(
                name: .projectGitRefsDidChange,
                operation: "deleteLocalTag",
                additionalInfo: ["tagName": tagName]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "deleteLocalTag",
                success: false,
                error: error,
                additionalInfo: ["tagName": tagName]
            )
            throw error
        }
    }

    func pushTag(named tagName: String, remote: String = "origin") throws {
        do {
            try gitCLI.pushTag(named: tagName, remote: remote)
            postEvent(
                name: .projectDidPush,
                operation: "pushTag",
                additionalInfo: ["tagName": tagName, "remote": remote]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "pushTag",
                success: false,
                error: error,
                additionalInfo: ["tagName": tagName, "remote": remote]
            )
            throw error
        }
    }

    func deleteRemoteTag(named tagName: String, remote: String = "origin") throws {
        do {
            try gitCLI.deleteRemoteTag(named: tagName, remote: remote)
            postEvent(
                name: .projectDidPush,
                operation: "deleteRemoteTag",
                additionalInfo: ["tagName": tagName, "remote": remote]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "deleteRemoteTag",
                success: false,
                error: error,
                additionalInfo: ["tagName": tagName, "remote": remote]
            )
            throw error
        }
    }
}

// MARK: - Git LFS

extension Project {
    func lfsStatus() -> GitRepositoryCLI.GitLFSStatus {
        gitCLI.lfsStatus()
    }

    func initializeLFS() throws {
        try gitCLI.initializeLFS()
    }

    func lfsLargeFileCandidates(thresholdBytes: Int64 = 50 * 1024 * 1024) throws -> [GitRepositoryCLI.GitLFSLargeFileCandidate] {
        try gitCLI.lfsLargeFileCandidates(thresholdBytes: thresholdBytes)
    }

    func lfsAttributeMismatches() throws -> [GitRepositoryCLI.GitLFSAttributeMismatch] {
        try gitCLI.lfsAttributeMismatches()
    }
}

// MARK: - Submodule

extension Project {
    func submodules() throws -> [GitRepositoryCLI.GitSubmodule] {
        try gitCLI.submodules()
    }

    func initializeSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        try gitCLI.initializeSubmodules(paths: paths, recursive: recursive, allowFileProtocol: allowFileProtocol)
    }

    func updateSubmodules(paths: [String] = [], recursive: Bool = true, allowFileProtocol: Bool = false) throws {
        try gitCLI.updateSubmodules(paths: paths, recursive: recursive, allowFileProtocol: allowFileProtocol)
    }

    func submoduleDiff(path: String) throws -> String {
        try gitCLI.submoduleDiff(path: path)
    }
}

// MARK: - Project Events


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
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
