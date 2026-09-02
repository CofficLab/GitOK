import Foundation
import KernelCore
import ProviderStatusBar
import SwiftUI
import XCTest
@testable import PluginStatusBar

@MainActor
final class StatusBarPluginTests: XCTestCase {
    func testOnBootInjectsLeadingAndTrailingItems() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)

        let plugin = StatusBarPlugin()
        try plugin.onBoot(kernel: kernel)

        // ProjectProviding / ThemeProviding 未注册：应优雅降级，不注入任何项。
        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }

    func testOnShutdownRemovesItems() throws {
        let kernel = KernelCoreContainer()
        let statusBar = DefaultStatusBarProviding()
        try kernel.registerProvider((any StatusBarProviding).self, statusBar)

        // 手动注入两项，验证 onShutdown 按 id 撤回。
        statusBar.addStatusBarItems([
            StatusBarItem(id: "\(StatusBarPlugin.itemPrefix).project", title: "p", placement: .leading) { EmptyView() },
            StatusBarItem(id: "\(StatusBarPlugin.itemPrefix).theme", title: "t", placement: .trailing) { EmptyView() },
        ])
        XCTAssertEqual(statusBar.statusBarItems.count, 2)

        let plugin = StatusBarPlugin()
        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(statusBar.statusBarItems.isEmpty)
    }
}
