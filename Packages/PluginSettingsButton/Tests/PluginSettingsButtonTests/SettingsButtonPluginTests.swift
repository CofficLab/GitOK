import Foundation
import KernelCore
import ProviderToolbar
import XCTest
@testable import PluginSettingsButton

@MainActor
final class SettingsButtonPluginTests: XCTestCase {
    func testOnBootRegistersTrailingToolbarItem() throws {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        try kernel.registerProvider((any ToolbarProviding).self, toolbar)

        let plugin = SettingsButtonPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(toolbar.toolbarItems.count, 1)
        XCTAssertEqual(toolbar.toolbarItems[0].id, SettingsButtonPlugin.toolbarItemID)
        XCTAssertEqual(toolbar.toolbarItems[0].placement, .trailing, "设置按钮应在右上角")
        XCTAssertEqual(toolbar.toolbarItems[0].category, .global)
    }

    func testOnShutdownRemovesToolbarItem() throws {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        try kernel.registerProvider((any ToolbarProviding).self, toolbar)

        let plugin = SettingsButtonPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    func testOnBootWithoutToolbarDoesNotThrow() throws {
        let kernel = KernelCoreContainer()
        let plugin = SettingsButtonPlugin()
        // ToolbarProviding 未注册：应优雅降级，不抛错。
        try plugin.onBoot(kernel: kernel)
    }
}
