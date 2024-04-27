import Foundation
import OSLog
import SwiftUI

class Git {
    static var label: String = "🔮 git "

    static func push(_ path: String, debugPrint: Bool = false) throws -> String {
        try Git.run("push", path: path, debugPrint: debugPrint)
    }

    static func getRemote(_ path: String) -> String {
        try! Git.run("remote get-url origin", path: path)
    }

    static func run(_ arguments: String, path: String, debugPrint: Bool = false) throws -> String {
        try Shell.run("cd \(path) && git \(arguments)", debugPrint: debugPrint)
    }
}

#Preview {
    AppPreview()
}
