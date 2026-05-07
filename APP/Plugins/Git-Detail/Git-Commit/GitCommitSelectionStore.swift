import Foundation

enum GitCommitSelectionStore {
    static let lastCommitKeyPrefix = "Git.lastSelectedCommit_"

    static func key(for projectPath: String) -> String {
        lastCommitKeyPrefix + projectPath
    }

    static func commitData(
        hash: String,
        message: String,
        author: String,
        date: Date
    ) -> [String: Any] {
        [
            "hash": hash,
            "message": message,
            "author": author,
            "date": date.timeIntervalSince1970,
        ]
    }

    static func selectedHash(from commitData: [String: Any]?) -> String? {
        commitData?["hash"] as? String
    }
}
