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
}

#Preview {
    AppPreview()
}
