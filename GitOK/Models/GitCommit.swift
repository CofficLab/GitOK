import Foundation
import SwiftUI
import OSLog

struct GitCommit {
    static func headFor(_ path: String) -> GitCommit {
        .init(isHead: true, path: path, hash: "HEAD", message: "当前")
    }

    var path: String
    var isHead = false
    var hash: String
    var message: String

    init(
        isHead: Bool = false,
        path: String = "/",
        hash: String = "",
        message: String = ""
    ) {
        self.isHead = isHead
        self.path = path
        self.hash = hash
        self.message = message
    }

    static func fromShellLine(_ l: String, path: String, seprator: String = "+") -> GitCommit {
        let components = l.components(separatedBy: seprator)
        let count = components.count
        let hash = count > 0 ? components[0] : ""
        let message = count > 1 ? components[1] : ""

        return GitCommit(path: path, hash: hash, message: message)
    }
    
    func checkIfSynced() throws -> Bool {
        isHead ? true : try! !Git.notSynced(path).contains(where: {
            $0.hash == self.hash
        })
    }
    
    func getFiles() -> [File] {
        if isHead {
            os_log("getFiles for HEAD")
            return try! Git.changedFile(path)
        } else {
            os_log("getFiles for commit")
            return try! Git.commitFiles(path, hash: hash)
        }
    }
}

extension GitCommit: Identifiable {
    var id: String {
        hash
    }
}

extension GitCommit: Hashable {}

extension GitCommit {
    static var autoCommitMessage = "\(CommitCategory.Chore.text) Auto Commit"
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
