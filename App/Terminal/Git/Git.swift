import Foundation
import OSLog
import SwiftUI
import MagicKit

class Git: SuperEvent, SuperLog {
    var emoji = "🔮"
    var shell = Shell()

    func getRemote(_ path: String) -> String {
        do {
            return try self.run("remote get-url origin", path: path)
        } catch let error {
            return error.localizedDescription
        }
    }
    
    func diff(_ path: String, verbose: Bool = false) throws -> String {
        try self.run("diff", path: path, verbose: verbose)
    }

    @discardableResult
    func run(_ arguments: String, path: String, verbose: Bool = false) throws -> String {
        let command = "cd '\(path)' && git \(arguments)"
        
        if verbose {
            os_log("\(self.t)Run -> \(command)")
        }

        return try self.shell.run(command, verbose: verbose)
    }
    
    func isGitProject(path: String, verbose: Bool = false) -> Bool {
        let gitPath = URL(fileURLWithPath: path).appendingPathComponent(".git").path
        return FileManager.default.fileExists(atPath: gitPath)
    }

    func hasUnCommittedChanges(path: String, verbose: Bool = false) -> Bool {
        if let status = try? self.run("status", path: path, verbose: verbose) {
            return status.contains("Changes not staged for commit")
        }
        return false
    }

    func getRemoteUrl(_ path: String) throws -> String {
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
}

// MARK: Status

extension Git {
    func status(_ path: String) throws -> String {
        try run("status", path: path)
    }
    
    func hasChanges(_ path: String) -> Bool {
        changedFile(path).count > 0
    }

    func changedFile(_ path: String) -> [File] {
        let verbose = false
        
        if verbose {
            os_log("\(self.t)GetChangedFile")
            os_log("  ➡️ Path -> \(path)")
        }
        
        if isGitProject(path: path) == false {
            return []
        }

        do {
            return try run("status --porcelain | awk '{print $2}'", path: path, verbose: verbose)
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
}

// MARK: Branch

extension Git {
    func getBranches(_ path: String, verbose: Bool = false) throws -> [Branch] {
        if self.isGitProject(path: path) == false {
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

        if verbose {
            os_log("\(self.t)GetBranches")
            print(branches)
        }

        return branches
    }

    func getCurrentBranch(_ path: String, verbose: Bool = false) throws -> Branch {
        let verbose = false

        if verbose {
            os_log("\(self.t)GetCurrentBranch -> \(path)")
        }

        return Branch.fromShellLine(try run("branch --show-current", path: path, verbose: verbose), path: path)
    }

    @discardableResult
    func setBranch(_ b: Branch, _ path: String, verbose: Bool = false) throws -> String {
        let result = try run("checkout \(b.name) -q", path: path, verbose: verbose)
        
        self.emitGitBranchChanged(branch: b.name)
        
        return result
    }
}

// MARK: Merge

extension Git {
    func merge(
        _ from: Branch,
        _ path: String,
        verbose: Bool = false,
        message: String = "merge"
    ) throws {
        try run("merge \(from.name) -m '\(message)'", path: path, verbose: verbose)
    }
    
    func mergeToMain(_ path: String, message: String = "merge") throws {
        try run("merge -m '\(message)'", path: path)
    }
}

#Preview {
    AppPreview()
}
