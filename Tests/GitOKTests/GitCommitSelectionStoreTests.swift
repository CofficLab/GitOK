import Foundation
import Testing

@Suite("GitCommitSelectionStoreTests")
struct GitCommitSelectionStoreTests {
    @Test("Key keeps project path boundary")
    func keyKeepsProjectPathBoundary() {
        #expect(GitCommitSelectionStore.key(for: "/tmp/repo") == "Git.lastSelectedCommit_/tmp/repo")
        #expect(GitCommitSelectionStore.key(for: "/tmp/repo-a") != GitCommitSelectionStore.key(for: "/tmp/repo-b"))
    }

    @Test("Commit data stores expected fields and selected hash extracts safely")
    func commitDataStoresExpectedFieldsAndSelectedHashExtractsSafely() {
        let date = Date(timeIntervalSince1970: 1234)
        let data = GitCommitSelectionStore.commitData(
            hash: "abc123",
            message: "Fix bug",
            author: "Ada",
            date: date
        )

        #expect(data["hash"] as? String == "abc123")
        #expect(data["message"] as? String == "Fix bug")
        #expect(data["author"] as? String == "Ada")
        #expect(data["date"] as? TimeInterval == 1234)
        #expect(GitCommitSelectionStore.selectedHash(from: data) == "abc123")
        #expect(GitCommitSelectionStore.selectedHash(from: ["message": "missing hash"]) == nil)
        #expect(GitCommitSelectionStore.selectedHash(from: nil) == nil)
    }
}
