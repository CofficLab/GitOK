import Foundation
import OSLog
import SwiftUI

class Git: SuperEvent {
    var label: String = "🔮 git "

    static func getRemote(_ path: String) -> String {
        do {
            return try Git.run("remote get-url origin", path: path)
        } catch let error {
            return error.localizedDescription
        }
    }
    
    static func diff(_ path: String, verbose: Bool = false) throws -> String {
        try Git.run("diff", path: path, verbose: verbose)
    }

    static func run(_ arguments: String, path: String, verbose: Bool = false) throws -> String {
        try Shell.run("cd '\(path)' && git \(arguments)", verbose: verbose)
    }
    
    static func isGitProject(path: String, verbose: Bool = false) -> Bool {
        do {
            return try Shell.run("ls -a '\(path)' | grep .git", verbose: verbose).count > 0
        } catch _ {
            return false
        }
    }
}

#Preview {
    AppPreview()
}
