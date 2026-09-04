import KernelCore
import ProviderRootView
import SwiftUI
import XCTest
@testable import PluginRootView

@MainActor
final class PluginRootViewTests: XCTestCase {
    func testPluginMetadata() {
        let plugin = RootViewPlugin()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.root-view")
        XCTAssertEqual(plugin.order, 5)
        XCTAssertFalse(plugin.metadata.name.isEmpty)
        XCTAssertFalse(plugin.metadata.description.isEmpty)
    }

    func testOnBootReplacesDefaultProvider() throws {
        let kernel = KernelCoreContainer()
        let defaultProvider = DefaultRootViewProvider()
        try kernel.registerProvider((any RootViewProviding).self, defaultProvider)

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 解析到的应该是插件自有的 GitOKRootViewProvider，而非默认实现。
        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertTrue(resolved is GitOKRootViewProvider)
        XCTAssertFalse(resolved === defaultProvider)
        XCTAssertTrue(resolved === plugin.provider)
    }

    func testOnShutdownRestoresDefaultProvider() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(kernel.resolveProvider((any RootViewProviding).self) is GitOKRootViewProvider)

        try plugin.onShutdown(kernel: kernel)
        // 恢复后应该不再是 GitOKRootViewProvider。
        let resolved = kernel.resolveProvider((any RootViewProviding).self)
        XCTAssertFalse(resolved is GitOKRootViewProvider)
        XCTAssertNotNil(resolved)
    }

    func testProviderDelegatesSetToolbarView() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        // 注入工具栏视图不应崩溃，说明委托链路正常。
        plugin.provider.setToolbarView(AnyView(Text("Toolbar")))
        plugin.provider.setSidebarView(AnyView(Text("Sidebar")))
        plugin.provider.setContentView(AnyView(Text("Content")))
        plugin.provider.setStatusBarView(AnyView(Text("Status")))
        plugin.provider.setContentHeaderView(AnyView(Text("Header")))
        plugin.provider.setContentFooterView(AnyView(Text("Footer")))

        // makeRootView 应正常返回。
        let rootView = plugin.provider.makeRootView()
        XCTAssertNotNil(rootView)
    }

    func testProviderOverlayOperations() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(plugin.provider.overlays.isEmpty)

        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 100) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 1)
        XCTAssertEqual(plugin.provider.overlays.first?.id, "test-overlay")

        // 同 id 不重复注册。
        plugin.provider.addOverlays([
            RootOverlayItem(id: "test-overlay", order: 200) { content in content },
        ])
        XCTAssertEqual(plugin.provider.overlays.count, 1)

        plugin.provider.removeOverlays(ids: ["test-overlay"])
        XCTAssertTrue(plugin.provider.overlays.isEmpty)
    }

    func testProviderRailViewOperations() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(plugin.provider.isRailViewVisible)
        plugin.provider.setRailViewVisible(false)
        XCTAssertFalse(plugin.provider.isRailViewVisible)
        plugin.provider.setRailViewVisible(true)
        XCTAssertTrue(plugin.provider.isRailViewVisible)
    }

    func testProviderContentViewHidden() throws {
        let kernel = KernelCoreContainer()
        try kernel.registerProvider((any RootViewProviding).self, DefaultRootViewProvider())

        let plugin = RootViewPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertFalse(plugin.provider.isContentViewHidden)
        plugin.provider.setContentViewHidden(true)
        XCTAssertTrue(plugin.provider.isContentViewHidden)
    }
}
