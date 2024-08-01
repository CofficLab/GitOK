import Foundation
import OSLog
import SwiftUI

class Git {
    static var label: String = "🔮 git "

    static func push(_ path: String) -> String {
        Git.run("push", path: path)
    }

    static func getRemote(_ path: String) -> String {
        Git.run("remote get-url origin", path: path)
    }

    static func run(_ arguments: String, path: String) -> String {
        Shell.run("cd \(path) && git \(arguments)")
    }
}

#Preview {
    AppPreview()
}
