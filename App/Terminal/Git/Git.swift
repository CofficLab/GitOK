import Foundation
import OSLog
import SwiftUI

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

#Preview {
    AppPreview()
}
