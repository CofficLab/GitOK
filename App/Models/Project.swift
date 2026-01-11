import Foundation
import LibGit2Swift
import OSLog
import SwiftData
import SwiftUI

// MARK: - Project Events

extension Notification.Name {
    static let projectDidAddFiles = Notification.Name("projectDidAddFiles")
    static let projectDidCommit = Notification.Name("projectDidCommit")
    static let projectDidPush = Notification.Name("projectDidPush")
    static let projectDidPull = Notification.Name("projectDidPull")
    static let projectDidMerge = Notification.Name("projectDidMerge")
    static let projectDidSync = Notification.Name("projectDidSync")
    static let projectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    static let projectDidUpdateUserInfo = Notification.Name("projectDidUpdateUserInfo")
    static let projectOperationDidFail = Notification.Name("projectOperationDidFail")
}

// MARK: - View Extensions for Project Events

extension View {
    func onProjectDidAddFiles(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidAddFiles)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidCommit(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidCommit)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidPush(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidPush)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidPull(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidPull)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidMerge(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidMerge)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidSync(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidSync)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidChangeBranch(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidChangeBranch)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectDidUpdateUserInfo(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectDidUpdateUserInfo)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }

    func onProjectOperationDidFail(perform action: @escaping (ProjectEventInfo) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .projectOperationDidFail)) { notification in
            if let userInfo = notification.userInfo, let eventInfo = userInfo["eventInfo"] as? ProjectEventInfo {
                action(eventInfo)
            }
        }
    }
}

struct ProjectEventInfo {
    let project: Project
    let operation: String
    let success: Bool
    let error: Error?
    let additionalInfo: [String: Any]?

    init(project: Project, operation: String, success: Bool = true, error: Error? = nil, additionalInfo: [String: Any]? = nil) {
        self.project = project
        self.operation = operation
        self.success = success
        self.error = error
        self.additionalInfo = additionalInfo
    }
}

@Model
final class Project {
    var t: String { "[\(title)] " }
    static var verbose = false
    static var null = Project(URL(fileURLWithPath: ""))
    static var order = [
        SortDescriptor<Project>(\.order, order: .forward),
    ]
    static var orderReverse = [
        SortDescriptor<Project>(\.order, order: .reverse),
    ]

    static let emoji = "🌳"
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

    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }

    // MARK: - Event Notification Helper

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
    static func checkGitRepository(at path: String) {
        LibGit2.isGitRepository(at: path)
    }
    
    var isGitRepo: Bool {
        if path.isEmpty { return false }
        return LibGit2.isGitRepository(at: self.path)
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
        return !(await isGitAsync())
    }

    func isClean(verbose: Bool = true) throws -> Bool {
        guard isGitRepo else {
            if verbose {
                os_log(.info, "\(self.t)🔄 Project is not a git repository")
            }

            return true
        }
        
        return try LibGit2.hasUncommittedChanges(at: self.path) == false
    }
    
    func hasNoUncommittedChanges() throws -> Bool {
        return try LibGit2.hasUncommittedChanges(at: self.path) == false
    }
}

// MARK: - Branch

extension Project {
    func getCurrentBranch() throws -> GitBranch? {
        try LibGit2.getCurrentBranchInfo(at: self.path)
    }

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
            // 使用 Process 执行 git checkout -b 命令
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["checkout", "-b", branchName]
            process.currentDirectoryURL = URL(fileURLWithPath: self.path)
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                throw NSError(
                    domain: "GitError",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create branch: \(output)"]
                )
            }
            
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
}

// MARK: - Add

extension Project {
    func addAll() throws {
        do {
            try LibGit2.addFiles([], at: self.path)
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
        try LibGit2.getConfig(key: "user.name", at: self.path)
    }

    func getUserEmail() throws -> String {
        try LibGit2.getConfig(key: "user.email", at: self.path)
    }

    /// 设置项目的Git用户信息（仅针对当前项目）
    /// - Parameters:
    ///   - userName: 用户名
    ///   - userEmail: 用户邮箱
    /// - Throws: Git操作异常
    func setUserConfig(name userName: String, email userEmail: String) throws {
        do {
            _ = try LibGit2.setUserConfig(name: userName, email: userEmail, at: self.path)
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
        try LibGit2.getUserConfig(at: self.path)
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
    func getUnpushedCommits() throws -> [GitCommit] {
        // LibGit2Swift hasn't specifically implemented unpushed commits, 
        // fallback to empty or implement if needed. 
        // For now, let's return empty to avoid build error.
        return []
    }

    func getUnPulledCommits() throws -> [GitCommit] {
        // LibGit2Swift hasn't implemented unpulled commits tracking yet
        // Returning empty array as fallback
        return []
    }

    func submit(_ message: String) throws {
        assert(Thread.isMainThread, "setCommit(_:) 必须在主线程调用，否则会导致线程安全问题！")
        do {
            try LibGit2.createCommit(message: message, at: self.path)
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

    func getUnPushedCommits() throws -> [GitCommit] {
        // LibGit2Swift hasn't implemented unpushed commits tracking yet
        // Returning empty array as fallback
        return []
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

    func changedFilesDetail(in atCommit: String) async throws -> [GitDiffFile] {
        // 使用 LibGit2Swift 获取指定commit修改的文件列表
        return try LibGit2.getCommitDiffFiles(atCommit: atCommit, at: self.path)
    }

    func untrackedFiles() async throws -> [GitDiffFile] {
        // For now, just get the diff file list which includes untracked files
        return try LibGit2.getDiffFileList(at: self.path, staged: false)
    }

    func stagedDiffFileList() async throws -> [GitDiffFile] {
        return try LibGit2.getDiffFileList(at: self.path, staged: true)
    }
    
    /// 丢弃文件的更改（恢复到 HEAD 版本）
    /// - Parameter filePath: 文件路径（相对于仓库根目录）
    /// - Throws: Git操作异常
    func discardFileChanges(_ filePath: String) throws {
        do {
            // 使用 git checkout -- <file> 丢弃工作区的更改
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            process.arguments = ["checkout", "--", filePath]
            process.currentDirectoryURL = URL(fileURLWithPath: self.path)
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                throw NSError(
                    domain: "GitError",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to discard changes: \(output)"]
                )
            }
            
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
    func push() throws {
        do {
            try LibGit2.push(at: self.path)
            postEvent(
                name: .projectDidPush,
                operation: "push"
            )
        } catch {
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
            try LibGit2.pull(at: self.path)
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
