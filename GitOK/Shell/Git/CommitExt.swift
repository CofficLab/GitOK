import Foundation
import OSLog
import SwiftUI

extension Git {
    // MARK: 查
    
    static func show(_ path: String, hash: String) throws -> String {
        try Git.run("show \(hash)", path: path)
    }
    
    static func commitFiles(_ path: String, hash: String) throws -> [File] {
        try Git.run("show \(hash) --pretty='' --name-only", path: path)
            .components(separatedBy: "\n")
            .map({
                File.fromLine($0, path: path)
            })
    }
    
    static func add(_ path: String) throws -> String {
        try Git.run("add -A .", path: path)
    }

    static func commit(_ path: String, commit: String) throws -> String {
        try Git.run("commit -a -m '\(commit)'", path: path)
    }
    
    static func commitAndPush(_ path: String, commit: String, debugPrint: Bool = false) throws -> String {
        do {
            let addMessage = try Git.add(path)
            let message = try Git.run("commit -a -m '\(commit)'", path: path)
            os_log("\(self.label)commitAndPush commit message->\(message)")
            let pushMessage = try Git.run("push --porcelain", path: path, debugPrint: debugPrint)
            os_log("\(self.label)commitAndPush push message->\(pushMessage)")
            
            return pushMessage
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
