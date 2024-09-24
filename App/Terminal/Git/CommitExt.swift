import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查

    func show(_ path: String, hash: String) throws -> String {
        try run("show \(hash)", path: path)
    }

    func commitFiles(_ path: String, hash: String) throws -> [File] {
        try run("show \(hash) --pretty='' --name-only", path: path)
            .components(separatedBy: "\n")
            .map({
                File.fromLine($0, path: path)
            })
    }

    func add(_ path: String, verbose: Bool = false) throws {
        let message = try run("add -A .", path: path)

        if verbose {
            os_log("\(self.t)Add -> \(message)")
        }
    }

    func commit(_ path: String, commit: String) throws -> String {
        self.emitGitCommitStart()
        let result = try run("commit -a -m '\(commit)'", path: path)
        self.emitGitCommitSuccess()
        
        return result
    }

    func getShortHash(_ path: String, _ hash: String) throws -> String {
        try run("rev-parse --short", path: path)
    }

    func log(_ path: String) throws -> String {
        try run("log", path: path)
    }

    func logs(_ path: String) throws -> [GitCommit] {
        try run("log --pretty=format:%H+%s", path: path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    func notSynced(_ path: String) throws -> [GitCommit] {
        try revList(path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
