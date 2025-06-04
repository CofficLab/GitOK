import Foundation
import MagicCore
import OSLog
import SwiftUI

class GitShell {
    static func add(_ path: String, verbose: Bool = false) throws {
        try run("add -A .", path: path)
    }

    @discardableResult
    static func commit(_ path: String, commit: String) throws -> String {
        emit(.gitCommitStart, object: nil)
        let result = try run("commit -a -m '\(commit)'", path: path, verbose: true)
        emit(.gitCommitSuccess, object: nil)

        return result
    }

    static func commitFiles(_ path: String, hash: String) throws -> [File] {
        let items = try run("show \(hash) --pretty='' --name-only", path: path, verbose: true)
            .components(separatedBy: "\n")
            .filter({
                $0.isNotEmpty
            })

        return items.map({
            File.fromLine($0, path: path)
        })
    }

    static func changedFile(_ path: String) -> [File] {
        if isGitProject(path: path) == false {
            return []
        }

        do {
            return try run("status --porcelain | awk '{print $2}'", path: path, verbose: false)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .filter({ $0.count > 0 })
                .map {
                    File.fromLine($0.trimmingCharacters(in: .whitespacesAndNewlines), path: path)
                }
        } catch _ {
            return []
        }
    }

    static func diff(_ path: String, verbose: Bool = false) throws -> String {
        try run("diff", path: path, verbose: verbose)
    }

    static func diffOfFile(_ path: String, file: File) throws -> DiffBlock {
        DiffBlock(block: try run("diff HEAD~1 -- \(file.name)", path: path))
    }

    static func diffFileFromCommit(path: String, hash: String, file: String) throws -> some View {
        let diffCommand = try run("show \(hash) -- \(file)", path: path)
        let diffBlock = DiffBlock(block: diffCommand)
        let lines = diffBlock.block.components(separatedBy: "\n")

        return VStack(alignment: .leading) {
            Text("Diff for \(file)")
                .font(.headline)
                .padding(.bottom, 4)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        DiffLineView(line: line)
                            .id(index)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    static func getBranches(_ path: String, verbose: Bool = false) throws -> [Branch] {
        if isGitProject(path: path) == false {
            return []
        }

        var branches: [Branch] = []

        do {
            branches = try run("branch", path: path)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
                .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter({
                    $0.count != 0
                })
                .map {
                    Branch.fromShellLine($0, path: path)
                }
        } catch let error {
            os_log(.error, "\(error.localizedDescription)")

            throw error
        }

        return branches
    }

    static func getCredentialHelper(_ path: String) throws -> String {
        do {
            return try run("config credential.helper", path: path)
        } catch let error {
            os_log(.error, "获取凭证失败: \(error.localizedDescription)")
            throw error
        }
    }

    static func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        if verbose {
            os_log("GetCurrentBranch -> \(path)")
        }

        return Branch.fromShellLine(try run("branch --show-current", path: path, verbose: verbose), path: path)
    }

    static func getFileLastContent(_ path: String, file: String) throws -> String {
        try run("show --textconv HEAD:\(file)", path: path, verbose: false)
    }

    static func getRemote(_ path: String) -> String {
        do {
            return try run("remote get-url origin", path: path)
        } catch let error {
            return error.localizedDescription
        }
    }

    static func getRemoteUrl(_ path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "config", "--get", "remote.origin.url"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw NSError(domain: "GitError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }

        return output
    }

    static func getShortHash(_ path: String, _ hash: String) throws -> String {
        try run("rev-parse --short", path: path)
    }

    static func getTag(_ path: String, _ hash: String) throws -> String {
        try run("tag --points-at \(hash)", path: path)
    }

    static func hasChanges(_ path: String) -> Bool {
        changedFile(path).count > 0
    }

    static func hasUnCommittedChanges(path: String, verbose: Bool = false) throws -> Bool {
        let status = try run("status", path: path, verbose: verbose)

        return status.contains("Changes not staged for commit")
    }

    static func isGitProject(path: String, verbose: Bool = false) -> Bool {
        let gitPath = URL(fileURLWithPath: path).appendingPathComponent(".git").path
        return FileManager.default.fileExists(atPath: gitPath)
    }

    static func log(_ path: String) throws -> String {
        try run("log", path: path)
    }

    static func logs(_ path: String) throws -> [GitCommit] {
        let result = try run("--no-pager log --pretty=format:%H+%an+%ad+%s", path: path, verbose: false)

        return result.components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    static func merge(_ from: Branch, _ path: String, verbose: Bool = false, message: String = "merge") throws {
        try run("merge \(from.name) -m '\(message)'", path: path, verbose: verbose)
    }

    static func mergeToMain(_ path: String, verbose: Bool = true) throws {
        try run("merge main && git branch -f main HEAD", path: path, verbose: verbose)
    }

    static func notSynced(_ path: String) throws -> [GitCommit] {
        try revList(path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    static func pull(_ path: String) throws {
        do {
            emit(.gitPullStart, object: nil)
            _ = try Shell.run("git pull", at: path)
            emit(.gitPullSuccess, object: nil)
        } catch let error {
            os_log(.error, "拉取失败: \(error.localizedDescription)")
            emit(.gitPullFailed, object: nil)
            throw error
        }
    }

    static func push(_ path: String) throws {
        do {
            emit(.gitPushStart, object: nil)
            _ = try Shell.run("git push", at: path)
            emit(.gitPushSuccess, object: nil)
        } catch let error {
            os_log(.error, "推送失败: \(error.localizedDescription)")
            emit(.gitPushFailed, object: nil)
            throw error
        }
    }

    static func push(_ path: String, username: String, token: String) throws {
        emit(.gitPushStart, object: nil)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "push"]
        process.environment = ["GIT_ASKPASS": "echo", "GIT_USERNAME": username, "GIT_PASSWORD": token]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            emit(.gitPushFailed, object: nil)
            throw NSError(domain: "GitError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }

        emit(.gitPushSuccess, object: nil)
    }

    static func revList(_ path: String) throws -> String {
        let verbose = true

        if verbose {
            os_log("RevList -> \(path)")
        }

        let currentBranch = try getCurrentBranch(path)

        if verbose {
            os_log("RevList -> \(currentBranch.name)")
        }

        return try run("rev-list HEAD ^origin/\(currentBranch.name)", path: path)
    }

    @discardableResult
    static func run(_ arguments: String, path: String, verbose: Bool = false) throws -> String {
        try Shell.run("cd '\(path)' && git \(arguments)", verbose: verbose)
    }

    @discardableResult
    static func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        let result = try run("checkout \(b.name) -q", path: path, verbose: verbose)

        GitShell.emit(.gitBranchChanged, object: b.name)

        return result
    }

    static func show(_ path: String, hash: String) throws -> String {
        try run("show \(hash)", path: path)
    }

    static func status(_ path: String) throws -> String {
        try run("status", path: path)
    }

    static func logsWithPagination(_ path: String, skip: Int = 0, limit: Int = 30) throws -> [GitCommit] {
        let result = try run("--no-pager log --pretty=format:%H+%an+%ad+%s --date=format:'%Y-%m-%d %H:%M:%S' --skip=\(skip) -n \(limit)", path: path, verbose: false)

        if result.isEmpty {
            return []
        }

        return result.components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }
}

fileprivate extension String {
    var diffColor: Color {
        if self.hasPrefix("+") {
            return .green
        } else if self.hasPrefix("-") {
            return .red
        }
        return .primary
    }

    var diffBackground: Color {
        if self.hasPrefix("+") {
            return Color.green.opacity(0.1)
        } else if self.hasPrefix("-") {
            return Color.red.opacity(0.1)
        }
        return Color.clear
    }
}

// 添加一个新的视图组件来处理每一行
private struct DiffLineView: View {
    let line: String

    var body: some View {
        Text(verbatim: line)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(line.diffColor)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(line.diffBackground)
    }
}

// MARK: Event

extension Notification.Name {
    static let gitPullStart = Notification.Name("gitPullStart")
    static let gitPullSuccess = Notification.Name("gitPullSuccess")
    static let gitPullFailed = Notification.Name("gitPullFailed")
    static let gitPushStart = Notification.Name("gitPushStart")
    static let gitPushSuccess = Notification.Name("gitPushSuccess")
    static let gitPushFailed = Notification.Name("gitPushFailed")
    static let gitCommitStart = Notification.Name("gitCommitStart")
    static let gitCommitSuccess = Notification.Name("gitCommitSuccess")
    static let gitCommitFailed = Notification.Name("gitCommitFailed")
    static let gitBranchChanged = Notification.Name("gitBranchChanged")
    static let gitProjectDeleted = Notification.Name("gitProjectDeleted")
}

extension GitShell {
    static func emit(_ name: Notification.Name, object: Any?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}

#Preview {
    AppPreview()
}
