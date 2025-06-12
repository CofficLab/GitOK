import Foundation
import MagicCore
import OSLog
import SwiftData
import SwiftUI

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

//    var headCommit: GitCommit {
//        GitCommit()
//    }

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
    func getCurrentBranch() throws -> Branch {
        let name = try ShellGit.currentBranch()

        return Branch(path: path, name: name)
    }

    func setCurrentBranch(_ branch: Branch) throws {
        try ShellGit.checkout(branch.name, at: self.path)
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
        try ShellGit.commit(message, at: self.path)
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
}

// MARK: - Remote

extension Project {
    func push() throws {
        try ShellGit.push(at: self.path)
    }

    func pull() throws {
        try ShellGit.pull(at: self.path)
    }

    func sync() throws {
        try self.push()
        try self.pull()
    }

    func getRemotes() throws -> [String] {
        try ShellGit.remotesArray()
    }

    func getFirstRemote() throws -> String? {
        try self.getRemotes().first
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
