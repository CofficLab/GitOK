import Foundation
import OSLog
import SwiftUI

class Git {
    static var label: String = "🔮 git "

    static func getRemote(_ path: String) -> String {
        try! Git.run("remote get-url origin", path: path)
    }
    
    static func diff(_ path: String, verbose: Bool = false) throws -> String {
        try Git.run("diff", path: path, verbose: verbose)
    }

    static func run(_ arguments: String, path: String, verbose: Bool = false) throws -> String {
        try Shell.run("cd '\(path)' && git \(arguments)", verbose: verbose)
    }
    
    static func isGitProject(path: String, verbose: Bool = false) throws -> Bool {
        try Shell.run("ls -a '\(path)' | grep .git", verbose: verbose).count > 0
    }
}

#Preview {
    AppPreview()
}
