import Foundation
import KernelCore
import ProviderDocsView
import ProviderToolbar
import SwiftUI
import XCTest
@testable import PluginSettingsButton

/// `SettingsButtonPlugin` 的「关于」条目与内核启动接线覆盖。
@MainActor
final class SettingsButtonPluginWiringTests: XCTestCase {

    private func makeKernel(withToolbar: Bool = true, withDocs: Bool = false) throws -> (
        kernel: KernelCoreContainer,
        toolbar: DefaultToolbarProviding,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let toolbar = DefaultToolbarProviding()
        let docs = DefaultDocsViewProviding()
        if withToolbar {
            try kernel.registerProvider((any ToolbarProviding).self, toolbar)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, toolbar, docs)
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterAddsAboutEntryAndOnUnregisterRemovesIt() throws {
        let (kernel, _, docs) = try makeKernel(withDocs: true)
        let plugin = SettingsButtonPlugin()

        try plugin.onRegister(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == plugin.id })

        try plugin.onUnregister(kernel: kernel)
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testOnRegisterWithoutDocsProviderIsSafe() throws {
        let (kernel, _, _) = try makeKernel(withDocs: false)
        let plugin = SettingsButtonPlugin()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    func testStartViaKernelRegistersToolbarItem() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = SettingsButtonPlugin()

        try kernel.start(plugins: [plugin])

        XCTAssertTrue(kernel.isPluginRegistered(id: plugin.id))
        XCTAssertTrue(toolbar.toolbarItems.contains { $0.id == SettingsButtonPlugin.toolbarItemID })
        try kernel.stop()
    }

    func testStopViaKernelRemovesToolbarItem() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = SettingsButtonPlugin()
        try kernel.start(plugins: [plugin])
        XCTAssertFalse(toolbar.toolbarItems.isEmpty)

        try kernel.stop()

        XCTAssertTrue(toolbar.toolbarItems.isEmpty)
    }

    // MARK: - 工具栏项

    func testToolbarItemViewCanBeConstructed() throws {
        let (kernel, toolbar, _) = try makeKernel()
        let plugin = SettingsButtonPlugin()

        try plugin.onBoot(kernel: kernel)
        defer { try? plugin.onShutdown(kernel: kernel) }

        let item = try XCTUnwrap(toolbar.toolbarItems.first)
        let view = item.makeView()
        XCTAssertTrue(type(of: view) == AnyView.self)
    }

    // MARK: - 元数据

    func testPluginMetadata() {
        let plugin = SettingsButtonPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.settings-button")
        XCTAssertEqual(plugin.order, 100)
        XCTAssertEqual(plugin.metadata.category, .system)
        XCTAssertEqual(plugin.metadata.policy, .required)
    }
}
