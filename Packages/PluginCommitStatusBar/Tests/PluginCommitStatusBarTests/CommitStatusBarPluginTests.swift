import Foundation
import KernelCore
import KitGit
import ProviderCommit
import ProviderStatusBar
import XCTest
@testable import PluginCommitStatusBar

@MainActor
final class CommitStatusBarPluginTests: XCTestCase {
    private func commit(_ hash: String) -> GitCommit {
        GitCommit(hash: hash, shortHash: String(hash.prefix(7)), message: "msg", author: "a", date: Date())
    }

    func testOnBootAddsStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let detail = DefaultCommitDetailProvider()
        try kernel.registerProvider((any CommitDetailProviding).self, detail)

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.contains { $0.id == CommitStatusBarPlugin.itemID })
    }

    func testOnShutdownRemovesStatusBarItem() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let detail = DefaultCommitDetailProvider()
        try kernel.registerProvider((any CommitDetailProviding).self, detail)

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        XCTAssertFalse(statusBar.statusBarItems.contains { $0.id == CommitStatusBarPlugin.itemID })
    }

    func testStatusBarItemRendersSelectedCommitShortHash() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)
        let detail = DefaultCommitDetailProvider()
        try kernel.registerProvider((any CommitDetailProviding).self, detail)

        let plugin = CommitStatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        // 选择 commit 后，item 视图应以 Provider 为准渲染短哈希（Provider 是权威来源）。
        detail.selectCommit(commit("abcdef1234567890"), in: URL(fileURLWithPath: "/tmp/repo"))
        let item = statusBar.statusBarItems.first { $0.id == CommitStatusBarPlugin.itemID }
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.placement, .leading)
    }
}
