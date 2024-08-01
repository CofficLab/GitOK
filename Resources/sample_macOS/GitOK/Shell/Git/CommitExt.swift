import Foundation
import OSLog
import SwiftUI

extension Git {
    static func add(_ path: String) -> String {
        Git.run("add .", path: path)
    }

    static func commit(_ path: String, commit: String) -> String {
        Git.run("commit -a -m '\(commit)'", path: path)
    }

    static func getShortHash(_ path: String, _ hash: String) -> String {
        Git.run("rev-parse --short", path: path)
    }

    static func log(_ path: String) -> String {
        Git.run("log", path: path)
    }

    static func logs(_ path: String) -> [GitCommit] {
        Git.run("log --pretty=format:%H+%s", path: path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }

    static func notSynced(_ path: String) -> [GitCommit] {
        Git.revList(path).components(separatedBy: "\n").map {
            GitCommit.fromShellLine($0, path: path, seprator: "+")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
