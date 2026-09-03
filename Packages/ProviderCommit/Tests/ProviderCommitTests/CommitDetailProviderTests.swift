import Foundation
import KitGit
import XCTest
@testable import ProviderCommit

@MainActor
final class CommitDetailProviderTests: XCTestCase {
    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg \(hash)", author: "a", date: Date())
    }

    func testSelectAndReadBack() {
        let provider = DefaultCommitDetailProvider()
        let url = URL(fileURLWithPath: "/tmp/repo")
        let c = commit("abc")
        provider.selectCommit(c, in: url)
        XCTAssertEqual(provider.selectedCommit?.hash, "abc")
        XCTAssertEqual(provider.selectedProjectURL, url)
    }

    func testObserverReceivesSelection() {
        let provider = DefaultCommitDetailProvider()
        var received: [CommitDetailEvent] = []
        let handle = provider.addObserver { received.append($0) }

        let url = URL(fileURLWithPath: "/tmp/repo")
        provider.selectCommit(commit("a"), in: url)
        XCTAssertEqual(received.count, 1)

        // 相同选择不重复广播
        provider.selectCommit(commit("a"), in: url)
        XCTAssertEqual(received.count, 1)

        provider.selectCommit(commit("b"), in: url)
        XCTAssertEqual(received.count, 2)

        provider.clearSelection()
        XCTAssertEqual(received.count, 3)
        XCTAssertNil(provider.selectedCommit)
        XCTAssertNil(provider.selectedProjectURL)

        handle.cancel()
    }

    func testObserverCancelStopsEvents() {
        let provider = DefaultCommitDetailProvider()
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        handle.cancel()
        provider.selectCommit(commit("x"), in: URL(fileURLWithPath: "/tmp/r"))
        XCTAssertEqual(count, 0)
    }

    func testSelectFileBroadcastsAndReadsBack() {
        let provider = DefaultCommitDetailProvider()
        var received: [CommitDetailEvent] = []
        let handle = provider.addObserver { received.append($0) }

        let url = URL(fileURLWithPath: "/tmp/repo")
        provider.selectCommit(commit("a"), in: url)
        received.removeAll()

        provider.selectFile("src/main.swift")
        XCTAssertEqual(provider.selectedFile, "src/main.swift")
        XCTAssertEqual(received, [.selectedFileChanged])

        // 相同文件不重复广播
        provider.selectFile("src/main.swift")
        XCTAssertEqual(received.count, 1)

        // 取消文件选择
        provider.selectFile(nil)
        XCTAssertNil(provider.selectedFile)
        XCTAssertEqual(received, [.selectedFileChanged, .selectedFileChanged])

        handle.cancel()
    }

    func testSelectCommitClearsSelectedFile() {
        let provider = DefaultCommitDetailProvider()
        let url = URL(fileURLWithPath: "/tmp/repo")
        provider.selectCommit(commit("a"), in: url)
        provider.selectFile("src/a.swift")
        XCTAssertEqual(provider.selectedFile, "src/a.swift")

        provider.selectCommit(commit("b"), in: url)
        XCTAssertNil(provider.selectedFile, "切换 commit 应清空选中文件")
    }

    func testClearSelectionClearsSelectedFile() {
        let provider = DefaultCommitDetailProvider()
        provider.selectCommit(commit("a"), in: URL(fileURLWithPath: "/tmp/repo"))
        provider.selectFile("src/a.swift")
        provider.clearSelection()
        XCTAssertNil(provider.selectedCommit)
        XCTAssertNil(provider.selectedFile)
    }
}
