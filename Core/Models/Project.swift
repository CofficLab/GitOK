import Foundation
import LibGit2Swift
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

    func getCommits(_ reason: String) -> [GitCommit] {
        let verbose = false

        if verbose {
            os_log("\(self.t)GetCommit(\(reason))")
        }

        do {
            return (try LibGit2.getCommitList(at: self.path))
        } catch let error {
            os_log(.error, "\(self.t)GetCommits has error")
            os_log(.error, "\(error)")

            return []
        }
    }

    func getBanners() -> [BannerFile] {
        let verbose = false

        if verbose {
            os_log("\(self.t)GetBanners for project -> \(self.path)")
        }

        return BannerRepo.shared.getBanners(from: self)
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

    /**
        异步检查项目是否为Git仓库

        使用异步方式避免阻塞主线程，解决CPU占用100%的问题

        ## 返回值
        异步返回是否为Git仓库的布尔值

        ## 示例
        ```swift
        let isGit = await project.isGitAsync()
        ```
     */
    func isGitAsync() async -> Bool {
        // 使用Task.detached避免阻塞主线程
        return await Task.detached(priority: .userInitiated) {
            return LibGit2.isGitRepository(at: self.path)
        }.value
    }

    func isNotGit() -> Bool { !isGitRepo }

    /**
        异步检查项目是否为Git仓库（非阻塞版本）

        使用异步方式避免阻塞主线程

        ## 返回值
        异步返回是否为Git仓库的布ool值
     */
    func isNotGitAsync() async -> Bool {
        return (await isGitAsync()) == false
    }

    /**
        更新 isGitRepo 缓存（同步）

        直接设置缓存值，用于避免竞态条件
     */
    func updateIsGitRepoCacheSync(_ value: Bool) {
        self._isGitRepo = value
    }

    /**
        更新 isGitRepo 缓存（异步）

        在后台检查 Git 仓库状态并更新缓存，避免阻塞主线程
     */
    func updateIsGitRepoCache() async {
        let result = await isGitAsync()
        await MainActor.run {
            self._isGitRepo = result
        }
    }

    func isClean(verbose: Bool = true) throws -> Bool {
        guard isGitRepo else {
            if verbose {
                os_log(.info, "\(self.t)🔄 Project is not a git repository")
            }

            return true
        }

        // 检查是否有未提交的已跟踪文件变更
        let hasUncommittedChanges = try LibGit2.hasUncommittedChanges(at: self.path, verbose: verbose)
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
        let unstagedFiles = try LibGit2.getDiffFileList(at: self.path, staged: false)

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
        return try LibGit2.hasUncommittedChanges(at: self.path, verbose: false) == false
    }
}

// MARK: - Branch

extension Project {
    /// 获取当前分支信息
    /// - Returns: 当前分支对象，如果获取失败返回 nil
    /// - Throws: Git 操作相关的错误
    func getCurrentBranch() throws -> GitBranch? {
        try LibGit2.getCurrentBranchInfo(at: self.path)
    }

    /// 切换到指定分支
    /// - Parameter branch: 要切换到的分支
    /// - Throws: Git 操作相关的错误
    func checkout(branch: GitBranch) throws {
        do {
            _ = try LibGit2.checkout(branch: branch.name, at: self.path)
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
        try LibGit2.getBranchList(at: self.path)
    }

    /// 创建新分支并切换到该分支
    /// - Parameter branchName: 分支名称
    /// - Throws: Git操作异常
    func createBranch(_ branchName: String) throws {
        do {
            // 使用 LibGit2Swift 创建并切换到新分支
            try LibGit2.checkoutNewBranch(named: branchName, at: self.path)

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
            _ = try LibGit2.checkout(branch: toBranch.name, at: self.path)
            postEvent(
                name: .projectDidChangeBranch,
                operation: "checkout",
                additionalInfo: ["branchName": toBranch.name, "reason": "merge_setup"]
            )

            // 执行合并
            try LibGit2.merge(branchName: fromBranch.name, at: self.path, verbose: false)
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
            try LibGit2.merge(branchName: branchName, at: self.path, verbose: false)

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
    /// 将所有更改的文件添加到Git暂存区
    /// - Throws: Git 操作相关的错误
    func addAll() throws {
        do {
            try LibGit2.addFiles([], at: self.path, verbose: false)
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
}

// MARK: - User

extension Project {
    func getUserName() throws -> String {
        try LibGit2.getConfig(key: "user.name", at: self.path, verbose: false)
    }

    func getUserEmail() throws -> String {
        try LibGit2.getConfig(key: "user.email", at: self.path, verbose: false)
    }

    /// 设置项目的Git用户信息（仅针对当前项目）
    /// - Parameters:
    ///   - userName: 用户名
    ///   - userEmail: 用户邮箱
    /// - Throws: Git操作异常
    func setUserConfig(name userName: String, email userEmail: String) throws {
        do {
            _ = try LibGit2.setUserConfig(name: userName, email: userEmail, at: self.path, verbose: false)
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
        try LibGit2.getUserConfig(at: self.path, verbose: false)
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
    /// 使用 LibGit2Swift 原生实现
    func getUnPushedCommits() async throws -> [GitCommit] {
        return try LibGit2.getUnPushedCommits(at: self.path, verbose: false)
    }

    /// 获取未拉取的提交（远程领先本地的提交）
    /// 注意：当前返回空数组，因为 LibGit2Swift 无法直接访问远程提交
    /// 但可以通过 getUnPulledCount() 获取数量
    func getUnPulledCommits() async throws -> [GitCommit] {
        // 由于 LibGit2Swift 无法直接访问远程提交，暂时返回空数组
        return []
    }

    /// 获取未拉取的提交数量（远程领先本地的提交数量）
    func getUnPulledCount() throws -> Int {
        return try LibGit2.getUnPulledCount(at: self.path)
    }

    func submit(_ message: String) throws {
        assert(Thread.isMainThread, "setCommit(_:) 必须在主线程调用，否则会导致线程安全问题！")
        do {
            _ = try LibGit2.createCommit(message: message, at: self.path, verbose: false)
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
        return try LibGit2.getCommitListWithPagination(at: self.path, page: page, size: limit)
    }
}

// MARK: - File

extension Project {
    func fileContent(at: String, file: String) throws -> String {
        try LibGit2.getFileContent(atCommit: at, file: file, at: self.path)
    }

    func fileContentChange(at commit: String, file: String) throws -> (before: String?, after: String?) {
        try LibGit2.getFileContentChange(atCommit: commit, file: file, at: self.path)
    }

    func uncommittedFileContentChange(file: String) throws -> (before: String?, after: String?) {
        try LibGit2.getUncommittedFileContentChange(for: file, at: self.path)
    }

    /// 获取指定提交中文件的 diff 字符串
    func fileDiff(at commit: String, file: String) throws -> String {
        try LibGit2.getFileDiff(atCommit: commit, for: file, at: self.path)
    }

    /// 获取未提交文件的 diff 字符串
    func uncommittedFileDiff(file: String) throws -> String {
        try LibGit2.getFileDiff(for: file, at: self.path, staged: false)
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

        // 使用 LibGit2Swift 获取指定commit修改的文件列表，并按文件路径排序
        return try LibGit2.getCommitDiffFiles(atCommit: atCommit, at: self.path)
            .sorted { $0.file < $1.file }
    }

    func untrackedFiles() async throws -> [GitDiffFile] {
        // Get both staged and unstaged changes to show all uncommitted changes
        let stagedFiles = try LibGit2.getDiffFileList(at: self.path, staged: true)
        let unstagedFiles = try LibGit2.getDiffFileList(at: self.path, staged: false)

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
        return try LibGit2.getDiffFileList(at: self.path, staged: true)
            .sorted { $0.file < $1.file }
    }

    /// 丢弃文件的更改（恢复到 HEAD 版本）
    /// - Parameter filePath: 文件路径（相对于仓库根目录）
    /// - Throws: Git操作异常
    func discardFileChanges(_ filePath: String) throws {
        do {
            // 使用 LibGit2Swift 丢弃工作区的更改
            try LibGit2.checkoutFile(filePath, at: self.path)

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
    /// 将工作区重置为HEAD状态，丢弃所有未提交的更改（包括已暂存和未暂存的）
    /// - Throws: Git操作异常
    func discardAllChanges() throws {
        do {
            // 使用硬重置一次性丢弃所有更改（包括暂存区和工作区）
            // 相比之前的逐个文件 checkout，这种方法能正确处理已暂存的文件
            try LibGit2.reset(to: nil, mode: "hard", at: self.path, verbose: false)

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
    // TODO: 实现stash功能，需要正确配置LibGit2Swift包依赖
    func stashSave(message: String? = nil) throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stash功能暂未实现"])
    }

    /// 获取stash列表
    /// - Returns: stash列表，每个stash包含索引和消息
    /// - Throws: Git操作异常
    func stashList() throws -> [(index: Int, message: String)] {
        // TODO: 实现stash列表功能
        return []
    }

    /// 应用指定的stash（保留stash）
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashApply(index: Int) throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stash功能暂未实现"])
    }

    /// 弹出指定的stash（应用并删除stash）
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashPop(index: Int) throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stash功能暂未实现"])
    }

    /// 删除指定的stash
    /// - Parameter index: stash的索引
    /// - Throws: Git操作异常
    func stashDrop(index: Int) throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stash功能暂未实现"])
    }

    /// 获取合并冲突文件列表
    /// - Returns: 冲突文件路径列表
    /// - Throws: Git操作异常
    func getMergeConflictFiles() async throws -> [String] {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "冲突解决功能暂未实现"])
    }

    /// 检查是否正在合并状态
    /// - Returns: 如果正在合并返回true
    /// - Throws: Git操作异常
    func isMerging() async throws -> Bool {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "冲突解决功能暂未实现"])
    }

    /// 检查是否有合并冲突
    /// - Returns: 如果有冲突返回true
    /// - Throws: Git操作异常
    func hasMergeConflicts() async throws -> Bool {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "冲突解决功能暂未实现"])
    }

    /// 中止合并操作
    /// - Throws: Git操作异常
    func abortMerge() async throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "冲突解决功能暂未实现"])
    }

    /// 继续合并操作（解决冲突后）
    /// - Parameter branchName: 要合并的分支名
    /// - Throws: Git操作异常
    func continueMerge(branchName: String) async throws {
        throw NSError(domain: "GitOK", code: -1, userInfo: [NSLocalizedDescriptionKey: "冲突解决功能暂未实现"])
    }

    /// 获取项目的README.md文件内容
    /// - Returns: README.md文件的内容，如果文件不存在则抛出异常
    /// - Throws: 文件不存在或读取错误
    func getReadmeContent() async throws -> String {
        let readmeFiles = ["README.md", "readme.md", "Readme.md", "README.MD"]
        let fileManager = FileManager.default

        for readmeFile in readmeFiles {
            let readmeURL = URL(fileURLWithPath: self.path).appendingPathComponent(readmeFile)
            if fileManager.fileExists(atPath: readmeURL.path) {
                return try String(contentsOf: readmeURL, encoding: .utf8)
            }
        }

        throw NSError(
            domain: "ProjectError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "README.md file not found"]
        )
    }

    /// 获取项目根目录的 .gitignore 内容
    /// - Returns: .gitignore 文件内容，如果不存在则抛出异常
    func getGitignoreContent() async throws -> String {
        let gitignoreURL = URL(fileURLWithPath: self.path).appendingPathComponent(".gitignore")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: gitignoreURL.path) else {
            throw NSError(
                domain: "ProjectError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: ".gitignore file not found"]
            )
        }

        return try String(contentsOf: gitignoreURL, encoding: .utf8)
    }

    /// 获取 LICENSE 内容（支持多种常见文件名）
    func getLicenseContent() async throws -> String {
        let licenseFiles = ["LICENSE", "LICENSE.txt", "License", "license"]
        let fileManager = FileManager.default

        for file in licenseFiles {
            let url = URL(fileURLWithPath: self.path).appendingPathComponent(file)
            if fileManager.fileExists(atPath: url.path) {
                return try String(contentsOf: url, encoding: .utf8)
            }
        }

        throw NSError(
            domain: "ProjectError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "LICENSE file not found"]
        )
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
            let currentBranch = try LibGit2.getCurrentBranch(at: self.path)
            os_log(.default, "📍 Current branch: \(currentBranch)")

            // 在推送前记录未推送的 commits
            let unpushedBeforePush = try LibGit2.getUnPushedCommits(at: self.path, verbose: false)

            // 处理 SSH URL 转换
            try performWithConvertedSSHURL(operation: "push") {
                try LibGit2.push(at: self.path, verbose: false)
            }

            // 在推送后记录未推送的 commits
            let unpushedAfterPush = try LibGit2.getUnPushedCommits(at: self.path, verbose: false)

            postEvent(
                name: .projectDidPush,
                operation: "push"
            )
        } catch {
            os_log(.default, "❌ Push failed: \(error.localizedDescription)")
            postEvent(
                name: .projectOperationDidFail,
                operation: "push",
                success: false,
                error: error
            )
            throw error
        }
    }

    func pull() throws {
        do {
            // 处理 SSH URL 转换
            try performWithConvertedSSHURL(operation: "pull") {
                try LibGit2.pull(at: self.path, verbose: false)
            }

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

    /// 执行 Git 操作，如果需要则转换 SSH URL
    /// - Parameters:
    ///   - operation: 操作名称（push/pull）
    ///   - block: 要执行的操作
    private func performWithConvertedSSHURL(operation: String, block: () throws -> Void) throws {
        // 获取当前远程 URL
        guard let remoteURL = LibGit2.getRemoteURL(at: self.path, remote: "origin") else {
            try block()
            return
        }

        // 检查是否需要转换
        let convertedURL = SSHHelper.applySSHConfig(to: remoteURL)

        if convertedURL == remoteURL {
            try block()
        } else {
            // 保存原始 URL
            let originalURL = remoteURL

            // 修改为转换后的 URL
            try LibGit2.setRemoteURL(at: self.path, remote: "origin", url: convertedURL)

            // 设置 defer 确保恢复原始 URL
            defer {
                do {
                    try LibGit2.setRemoteURL(at: self.path, remote: "origin", url: originalURL)
                } catch {
                    os_log(.error, "\(self.t)Failed to restore original URL: \(error)")
                }
            }

            // 执行操作
            try block()
        }
    }

    func sync() throws {
        do {
            try self.push()
            try self.pull()
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
        try LibGit2.getRemoteList(at: self.path)
    }
}

// MARK: - Tag

extension Project {
    func tags(for commit: String) throws -> [String] {
        try LibGit2.getTags(at: self.path, for: commit)
    }

    func getTags(commit: String) throws -> [String] {
        try tags(for: commit)
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
