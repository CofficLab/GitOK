import Foundation
import KernelCore
import ProviderCommitDetail
import ProviderContentView
import XCTest
@testable import PluginCommitDetail

@MainActor
final class CommitDetailPluginTests: XCTestCase {
    func testOnBootRegistersContentThroughContentViewProviding() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        let detail = DefaultCommitDetailProvider()
        try kernel.registerProvider((any CommitDetailProviding).self, detail)

        let plugin = CommitDetailPlugin()
        try plugin.onBoot(kernel: kernel)

        // ContentViewProviding 已注入内容（CommitDetailView）。
        let host = contentView.makeContentView()
        XCTAssertFalse(String(describing: host).isEmpty)
    }

    func testOnShutdownClearsContent() throws {
        let kernel = KernelCoreContainer()
        let contentView = DefaultContentViewProviding()
        try kernel.registerProvider((any ContentViewProviding).self, contentView)
        let detail = DefaultCommitDetailProvider()
        try kernel.registerProvider((any CommitDetailProviding).self, detail)

        let plugin = CommitDetailPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
    }
}
