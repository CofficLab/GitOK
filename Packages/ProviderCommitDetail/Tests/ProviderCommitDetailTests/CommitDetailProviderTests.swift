import Foundation
import KitGit
import XCTest
@testable import ProviderCommitDetail

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
}
