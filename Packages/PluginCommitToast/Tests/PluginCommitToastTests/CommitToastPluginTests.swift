import Foundation
import KernelCore
import KitGit
import ProviderCommit
import ProviderToast
import XCTest
@testable import PluginCommitToast

@MainActor
final class CommitToastPluginTests: XCTestCase {
    /// 测试用 toast 记录器。
    private final class RecordingToastProvider: ToastProviding {
        var received: [LumiToast] = []
        func show(_ toast: LumiToast) {
            received.append(toast)
        }
    }

    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg \(hash)", author: "a", date: Date())
    }

    func testOnBootReplacesCommitDetailProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        let resolved = kernel.resolveProvider((any CommitDetailProviding).self)
        XCTAssertTrue(resolved is ToastCommitDetailProvider)
    }

    func testSelectCommitFiresToast() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any CommitDetailProviding).self)!
        provider.selectCommit(commit("abc"), in: URL(fileURLWithPath: "/tmp/repo"))

        XCTAssertEqual(toast.received.count, 1)
        XCTAssertEqual(toast.received[0].style, .info)
        XCTAssertEqual(provider.selectedCommit?.hash, "abc")
    }

    func testSameCommitSelectionDoesNotReToast() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any CommitDetailProviding).self)!
        let url = URL(fileURLWithPath: "/tmp/repo")
        provider.selectCommit(commit("abc"), in: url)
        provider.selectCommit(commit("abc"), in: url) // 相同选择：不应重复通知

        XCTAssertEqual(toast.received.count, 1)
    }

    func testClearSelectionFiresToast() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        let toast = RecordingToastProvider()
        try kernel.registerProvider((any ToastProviding).self, toast)

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any CommitDetailProviding).self)!
        provider.selectCommit(commit("abc"), in: URL(fileURLWithPath: "/tmp/repo"))
        provider.clearSelection()

        XCTAssertEqual(toast.received.count, 2)
        XCTAssertNil(provider.selectedCommit)
    }

    func testObserverStillReceivesSelectionEvents() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any CommitDetailProviding).self, DefaultCommitDetailProvider())
        try kernel.registerProvider((any ToastProviding).self, RecordingToastProvider())

        let plugin = CommitToastPlugin()
        try plugin.onBoot(kernel: kernel)

        let provider = kernel.resolveProvider((any CommitDetailProviding).self)!
        var count = 0
        let handle = provider.addObserver { _ in count += 1 }
        provider.selectCommit(commit("xyz"), in: URL(fileURLWithPath: "/tmp/repo"))
        XCTAssertEqual(count, 1)
        handle.cancel()
    }
}
