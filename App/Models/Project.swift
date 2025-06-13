import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI

// MARK: - Project Events
extension Notification.Name {
    static let projectDidAddFiles = Notification.Name("projectDidAddFiles")
    static let projectDidCommit = Notification.Name("projectDidCommit")
    static let projectDidPush = Notification.Name("projectDidPush")
    static let projectDidPull = Notification.Name("projectDidPull")
    static let projectDidSync = Notification.Name("projectDidSync")
    static let projectDidChangeBranch = Notification.Name("projectDidChangeBranch")
    static let projectOperationDidFail = Notification.Name("projectOperationDidFail")
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
    static var verbose = true
    static var null = Project(URL(fileURLWithPath: ""))
    static var order = [
        SortDescriptor<Project>(\.order, order: .forward),
    ]
    static var orderReverse = [
        SortDescriptor<Project>(\.order, order: .reverse),
    ]

    var label: String { "🌳 Project::" }
    var timestamp: Date
    var url: URL
    var order: Int16 = 0

    var title: String {
        url.lastPathComponent
    }

    var path: String {
        url.path
    }

    var isGit: Bool {
        ShellGit.isGitRepository(at: path)
    }

    var isNotGit: Bool { !isGit }

    var isClean: Bool {
        isGit && noUncommittedChanges
    }

    var noUncommittedChanges: Bool {
        try! self.hasUnCommittedChanges() == false
    }

    init(_ url: URL) {
        self.timestamp = .now
        self.url = url
    }
    
    // MARK: - Event Notification Helper
    private func postEvent(name: Notification.Name, operation: String, success: Bool = true, error: Error? = nil, additionalInfo: [String: Any]? = nil) {
        let eventInfo = ProjectEventInfo(
            project: self,
            operation: operation,
            success: success,
            error: error,
            additionalInfo: additionalInfo
        )
        
        NotificationCenter.default.post(
            name: name,
            object: self,
            userInfo: ["eventInfo": eventInfo]
        )
        
        if Self.verbose {
            os_log("\(self.label)Event posted: \(operation) - Success: \(success)")
        }
    }

    func getCommits(_ reason: String) -> [GitCommit] {
        let verbose = false

        if verbose {
            os_log("\(self.label)GetCommit(\(reason))")
        }

        do {
            return (try ShellGit.commitList(limit: 10, at: self.path))
        } catch let error {
            os_log(.error, "\(self.label)GetCommits has error")
            os_log(.error, "\(error)")

            return []
        }
    }

    func hasUnCommittedChanges() throws -> Bool {
        try ShellGit.hasUncommittedChanges(at: self.path) == false
    }

    func getBanners() throws -> [BannerModel] {
        let verbose = false

        if verbose {
            os_log("\(self.label)GetBanners for project -> \(self.path)")
        }

        return try BannerModel.all(self)
    }

    func getIcons() throws -> [IconModel] {
        let verbose = false

        if verbose {
            os_log("\(self.label)GetIcons for project -> \(self.path)")
        }

        return try IconModel.all(self.path)
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

// MARK: - Branch

extension Project {
    func getCurrentBranch() throws -> GitBranch? {
        try ShellGit.currentBranchInfo(at: self.path)
    }

    func setCurrentBranch(_ branch: GitBranch) throws {
        do {
            try ShellGit.checkout(branch.name, at: self.path)
            postEvent(
                name: .projectDidChangeBranch,
                operation: "changeBranch",
                additionalInfo: ["branchName": branch.name]
            )
        } catch {
            postEvent(
                name: .projectOperationDidFail,
                operation: "changeBranch",
                success: false,
                error: error,
                additionalInfo: ["branchName": branch.name]
            )
            throw error
        }
    }

    func getBranches() throws -> [GitBranch] {
        try ShellGit.branchList(at: self.path)
    }
}

// MARK: - Add

extension Project {
    func addAll() throws {
        do {
            try ShellGit.add([], at: self.path)
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
        try ShellGit.userName()
    }

    func getUserEmail() throws -> String {
        try ShellGit.userEmail()
    }
}

// MARK: - Commit

extension Project {
    func getUnPushedCommits() throws -> [GitCommit] {
        try ShellGit.unpushedCommitList(remote: "origin", branch: nil, at: self.path)
    }

    func submit(_ message: String) throws {
        do {
            try ShellGit.commit(message: message, at: self.path)
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
        try ShellGit.commitListWithPagination(page: page, size: limit, at: self.path)
    }
}

// MARK: - File

extension Project {
    func fileContent(at: String, file: String) throws -> String {
        try ShellGit.fileContent(atCommit: at, file: file, at: self.path)
    }

    func fileContentChange(at commit: String, file: String) throws -> (before: String?, after: String?) {
        try ShellGit.fileContentChange(at: commit, file: file, repoPath: self.path)
    }

    func uncommittedFileContentChange(file: String) throws -> (before: String?, after: String?) {
        try ShellGit.uncommittedFileContentChange(file: file, repoPath: self.path)
    }

    func fileList(atCommit: String) throws -> [GitDiffFile] {
        try ShellGit.changedFilesDetail(in: atCommit, at: self.path)
    }

    func untrackedFiles() throws -> [GitDiffFile] {
        try ShellGit.diffFileList(staged: false, at: self.path)
    }

    func stagedFiles() throws -> [GitDiffFile] {
        try ShellGit.diffFileList(staged: true, at: self.path)
    }
}

// MARK: - Remote

extension Project {
    func push() throws {
        do {
            try ShellGit.push(at: self.path)
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
            try ShellGit.pull(at: self.path)
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

    func getRemotes() throws -> [String] {
        try ShellGit.remotesArray()
    }

    func getFirstRemote() throws -> String? {
        try self.getRemotes().first
    }
}

// MARK: - Tag

extension Project {
    func getTags(commit: String) throws -> [String] {
        try ShellGit.tags(for: commit, at: self.path)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
