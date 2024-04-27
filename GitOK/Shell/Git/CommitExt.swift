import Foundation
import OSLog
import SwiftUI

extension Git {
    static func add(_ path: String) throws -> String {
        try Git.run("add .", path: path)
    }

    static func commit(_ path: String, commit: String) throws -> String {
        try Git.run("commit -a -m '\(commit)'", path: path)
    }
    
    static func commitAndPush(_ path: String, commit: String, debugPrint: Bool = false) throws -> String {
        do {
            _ = try Git.run("commit -a -m '\(commit)'", path: path)
            return try Git.run("push", path: path, debugPrint: debugPrint)
        } catch let error {
            throw error
        }
    }

    static func getShortHash(_ path: String, _ hash: String) throws -> String {
        try Git.run("rev-parse --short", path: path)
    }

    static func log(_ path: String) throws -> String {
        try Git.run("log", path: path)
    }

    static func logs(_ path: String) throws -> [GitCommit] {
        try Git.run("log --pretty=format:%H+%s", path: path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    static func notSynced(_ path: String) throws -> [GitCommit] {
        try Git.revList(path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
