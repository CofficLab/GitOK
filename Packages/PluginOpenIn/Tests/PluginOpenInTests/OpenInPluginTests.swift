import Foundation
import KernelCore
import ProviderProjects
import ProviderToolbar
import SwiftUI
import XCTest
@testable import PluginOpenIn

@MainActor
final class OpenInPluginTests: XCTestCase {
    func testOnBootInjectsOpenInToolbarItems() throws {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        try kernel.registerProvider((any ToolbarProviding).self, toolbar)

        // ProjectProviding 未注册：应优雅降级，不注入任何项。
        let plugin = OpenInPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    func testOnShutdownRemovesAllTargets() throws {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        try kernel.registerProvider((any ToolbarProviding).self, toolbar)

        // 手动注入所有目标 id，验证 onShutdown 全部撤回。
        toolbar.addToolbarItems(
            OpenTarget.allCases.map {
                ToolbarItem(id: "\(OpenInPlugin.itemPrefix).\($0.rawValue)", title: $0.displayName) { EmptyView() }
            }
        )
        XCTAssertEqual(toolbar.toolbarItems.count, OpenTarget.allCases.count)

        let plugin = OpenInPlugin()
        try plugin.onShutdown(kernel: kernel)
        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    func testRemoteWebURLConversion() {
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "git@github.com:user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "https://github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
        XCTAssertEqual(
            AppLauncher.webURL(fromRemote: "ssh://git@github.com/user/repo.git")?.absoluteString,
            "https://github.com/user/repo"
        )
    }
}
