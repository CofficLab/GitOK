import Foundation

public enum GitCommitSelectionStore {
    public static let lastCommitKeyPrefix = "Git.lastSelectedCommit_"

    public static func key(for projectPath: String) -> String {
        lastCommitKeyPrefix + projectPath
    }

    public static func commitData(
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

    public static func selectedHash(from commitData: [String: Any]?) -> String? {
        commitData?["hash"] as? String
    }
}
