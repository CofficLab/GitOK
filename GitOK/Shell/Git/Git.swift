import Foundation
import OSLog
import SwiftUI

class Git {
    static var label: String = "🔮 git "

    static func push(_ path: String, debugPrint: Bool = false) throws -> String {
//        let noNeed = try Git.run("log origin/dev..HEAD", path: path).isEmpty
//        
//        if noNeed {
//            return "已经同步"
//        }
        
        return try Git.run("push --porcelain", path: path, debugPrint: debugPrint)
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
