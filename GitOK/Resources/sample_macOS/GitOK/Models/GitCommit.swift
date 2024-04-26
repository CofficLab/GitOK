import Foundation
import SwiftUI

struct GitCommit {
    static var head: GitCommit = .init(isHead: true, message: "当前")

    var path: String
    var uuid: String
    var isHead = false
    var hash: String
    var message: String

    init(isHead: Bool = false, path: String = "/", hash: String = "", message: String = "") {
        uuid = UUID().uuidString
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
    
    func checkIfSynced() -> Bool {
        isHead ? true : !Git.notSynced(path).contains(where: {
            $0.hash == self.hash
        })
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
