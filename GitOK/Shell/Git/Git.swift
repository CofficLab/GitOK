import Foundation
import OSLog
import SwiftUI

class Git {
    static var label: String = "🔮 git "

    static func push(_ path: String, verbose: Bool = false) throws -> String {
        try Git.run("push --porcelain", path: path, verbose: verbose)
    }

    static func getRemote(_ path: String) -> String {
        try! Git.run("remote get-url origin", path: path)
    }
    
    static func diff(_ path: String, verbose: Bool = false) throws -> String {
        try Git.run("diff", path: path, verbose: verbose)
    }

    static func run(_ arguments: String, path: String, verbose: Bool = false) throws -> String {
        try Shell.run("cd \(path) && git \(arguments)", verbose: verbose)
    }
}

#Preview {
    AppPreview()
}
