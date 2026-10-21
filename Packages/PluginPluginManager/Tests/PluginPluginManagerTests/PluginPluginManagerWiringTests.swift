import Foundation
import KernelCore
import ProviderDocsView
import ProviderPluginManaging
import ProviderSettingView
import SwiftUI
import XCTest
@testable import PluginPluginManager

// MARK: - Test doubles

/// `PluginManaging` 的可控替身。
@MainActor
private final class PluginManagingStub: PluginManaging {
    var allPlugins: [any SuperPlugin] = []
    var configurablePlugins: [any SuperPlugin] = []
    var pluginCount = 0
    var enabledCount = 0
    var lastErrorDescription: String?

    private var observers: [UUID: (PluginManagingEvent) -> Void] = [:]
    private(set) var observerCount = 0

    func plugin(id: String) -> (any SuperPlugin)? {
        allPlugins.first { $0.id == id }
    }

    func isRegistered(id: String) -> Bool {
        plugin(id: id) != nil
    }

    func unloadPlugin(id: String) throws {}
    func reloadPlugin(id: String) throws {}
    func enabledPlugins(from candidates: [any SuperPlugin]) -> [any SuperPlugin] { candidates }

    func enablePlugin(id: String) async -> Bool { true }
    func disablePlugin(id: String) async -> Bool { true }
    func isEnabled(id: String) -> Bool { true }

    @discardableResult
    func addPluginObserver(
        _ callback: @escaping (PluginManagingEvent) -> Void
    ) -> any PluginManagingObserverHandle {
        let id = UUID()
        observers[id] = callback
        observerCount += 1
        return PluginManagingHandle { [weak self] in
            self?.observers.removeValue(forKey: id)
            self?.observerCount -= 1
        }
    }

    /// 手动派发插件管理事件。
    func send(_ event: PluginManagingEvent) {
        for callback in observers.values { callback(event) }
    }
}

@MainActor
private final class PluginManagingHandle: PluginManagingObserverHandle {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() { onCancel() }
}

/// 测试用的空插件。
@MainActor
private final class DummyPlugin: SuperPlugin {
    let id = "com.coffic.gitok.plugin.test-dummy"
    let metadata = PluginMetadata(
        id: "com.coffic.gitok.plugin.test-dummy",
        name: "Dummy",
        description: "dummy",
        category: .system,
        stage: .stable,
        policy: .required
    )
}

// MARK: - Tests

/// `PluginPluginManager` 的生命周期接线覆盖。
@MainActor
final class PluginPluginManagerWiringTests: XCTestCase {

    private func makeKernel(
        withSettings: Bool = true,
        withManager: Bool = true,
        withDocs: Bool = false
    ) throws -> (
        kernel: KernelCoreContainer,
        settings: DefaultSettingViewProviding,
        manager: PluginManagingStub,
        docs: DefaultDocsViewProviding
    ) {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        let manager = PluginManagingStub()
        let docs = DefaultDocsViewProviding()
        if withSettings {
            try kernel.registerProvider((any SettingViewProviding).self, settings)
        }
        if withManager {
            try kernel.registerProvider((any PluginManaging).self, manager)
        }
        if withDocs {
            try kernel.registerProvider((any DocsViewProviding).self, docs)
        }
        return (kernel, settings, manager, docs)
    }

    // MARK: - 元数据

    func testPluginMetadata() {
        let plugin = PluginPluginManager()
        XCTAssertEqual(plugin.id, "com.coffic.gitok.plugin.plugin-manager")
        XCTAssertEqual(plugin.order, 90)
        XCTAssertEqual(plugin.metadata.id, "com.coffic.gitok.plugin.plugin-manager")
        XCTAssertEqual(plugin.metadata.name, "Plugin Management")
        XCTAssertEqual(plugin.metadata.policy, .required)
        XCTAssertEqual(plugin.metadata.category, .system)
        XCTAssertEqual(plugin.metadata.stage, .stable)
    }

    // MARK: - 守卫链

    func testBootWithoutSettingViewProviderDoesNotRegisterEntry() throws {
        let (kernel, _, _, _) = try makeKernel(withSettings: false)
        let plugin = PluginPluginManager()

        try plugin.onBoot(kernel: kernel)

        XCTAssertNil(kernel.resolveProvider((any SettingViewProviding).self))
    }

    func testBootWithoutPluginManagingDoesNotRegisterEntry() throws {
        let (kernel, settings, _, _) = try makeKernel(withManager: false)
        let plugin = PluginPluginManager()

        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(settings.entries.isEmpty)
    }

    // MARK: - 入口项

    func testBootRegistersPluginManagerSettingEntry() throws {
        let (kernel, settings, _, _) = try makeKernel()
        let plugin = PluginPluginManager()

        try plugin.onBoot(kernel: kernel)

        XCTAssertEqual(settings.entries.count, 1)
        let entry = try XCTUnwrap(settings.entries.first)
        XCTAssertEqual(entry.id, PluginPluginManager.settingsEntryID)
        XCTAssertEqual(entry.systemImage, "puzzlepiece.extension")
        XCTAssertEqual(entry.order, 3)
        XCTAssertFalse(entry.title.isEmpty)
    }

    func testSettingEntryDetailViewIsBuildable() throws {
        let (kernel, settings, _, _) = try makeKernel()
        let plugin = PluginPluginManager()

        try plugin.onBoot(kernel: kernel)

        let entry = try XCTUnwrap(settings.entries.first)
        let detail = entry.makeDetailView()
        XCTAssertTrue(type(of: detail) == AnyView.self)
    }

    func testShutdownRemovesPluginManagerSettingEntry() throws {
        let (kernel, settings, _, _) = try makeKernel()
        let plugin = PluginPluginManager()
        try plugin.onBoot(kernel: kernel)

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(settings.entries.isEmpty)
    }

    func testShutdownWithoutBootIsSafe() throws {
        let (kernel, settings, _, _) = try makeKernel()
        let plugin = PluginPluginManager()

        try plugin.onShutdown(kernel: kernel)

        XCTAssertTrue(settings.entries.isEmpty)
    }

    // MARK: - onReady 的兜底 about 页

    func testOnReadyGeneratesDefaultAboutEntryForPluginWithoutAbout() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        let dummy = DummyPlugin()
        try kernel.registerPlugin(dummy)

        try plugin.onReady(kernel: kernel)

        XCTAssertTrue(docs.aboutEntries.contains { $0.id == dummy.id })
        // 未注册进内核的插件管理器自身不会被补页。
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testGeneratedDefaultAboutViewIsBuildable() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        let dummy = DummyPlugin()
        try kernel.registerPlugin(dummy)

        try plugin.onReady(kernel: kernel)

        let entry = try XCTUnwrap(docs.aboutEntries.first { $0.id == dummy.id })
        let view = entry.makeView()
        XCTAssertTrue(type(of: view) == AnyView.self)
    }

    func testOnReadyKeepsPluginProvidedAboutEntry() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        let dummy = DummyPlugin()
        try kernel.registerPlugin(dummy)
        docs.addAbout(DocsEntry(id: dummy.id, name: "Custom") { EmptyView() })

        try plugin.onReady(kernel: kernel)

        // 插件自己的页面仍然在，且没有被替换成默认页（默认页会用插件名重建条目）。
        let entry = try XCTUnwrap(docs.aboutEntries.first { $0.id == dummy.id })
        XCTAssertEqual(entry.name, "Custom")
    }

    func testOnReadyIsIdempotent() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        let dummy = DummyPlugin()
        try kernel.registerPlugin(dummy)

        try plugin.onReady(kernel: kernel)
        try plugin.onReady(kernel: kernel)

        XCTAssertEqual(docs.aboutEntries.filter { $0.id == dummy.id }.count, 1)
    }

    func testShutdownRemovesGeneratedAboutEntries() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        let dummy = DummyPlugin()
        try kernel.registerPlugin(dummy)
        try plugin.onReady(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == dummy.id })

        try plugin.onShutdown(kernel: kernel)

        XCTAssertFalse(docs.aboutEntries.contains { $0.id == dummy.id })
    }

    func testOnReadyWithoutDocsProviderIsNoop() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = PluginPluginManager()
        try kernel.registerPlugin(DummyPlugin())

        try plugin.onReady(kernel: kernel)
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterAddsManualAndAboutEntries() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()

        try plugin.onRegister(kernel: kernel)

        XCTAssertTrue(docs.manualEntries.contains { $0.id == plugin.id })
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testRegisteredDocsViewsAreBuildable() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()

        try plugin.onRegister(kernel: kernel)

        let manual = try XCTUnwrap(docs.manualEntries.first { $0.id == plugin.id })
        let about = try XCTUnwrap(docs.aboutEntries.first { $0.id == plugin.id })
        XCTAssertTrue(type(of: manual.makeView()) == AnyView.self)
        XCTAssertTrue(type(of: about.makeView()) == AnyView.self)
    }

    func testOnUnregisterRemovesDocsEntries() throws {
        let (kernel, _, _, docs) = try makeKernel(withDocs: true)
        let plugin = PluginPluginManager()
        try plugin.onRegister(kernel: kernel)

        try plugin.onUnregister(kernel: kernel)

        XCTAssertFalse(docs.manualEntries.contains { $0.id == plugin.id })
        XCTAssertFalse(docs.aboutEntries.contains { $0.id == plugin.id })
    }

    func testRegisterWithoutDocsProviderIsSafe() throws {
        let (kernel, _, _, _) = try makeKernel(withDocs: false)
        let plugin = PluginPluginManager()

        try plugin.onRegister(kernel: kernel)
        try plugin.onUnregister(kernel: kernel)
    }

    // MARK: - kernel.start

    func testStartViaKernelRegistersSettingEntry() throws {
        let (kernel, settings, _, _) = try makeKernel()
        let plugin = PluginPluginManager()

        try kernel.start(plugins: [plugin])

        XCTAssertTrue(kernel.isPluginRegistered(id: plugin.id))
        XCTAssertEqual(settings.entries.count, 1)
        try kernel.stop()
    }
}

/// `PluginManagementViewModel` 的观察行为覆盖。
@MainActor
final class PluginManagementViewModelTests: XCTestCase {

    func testRevisionStartsAtZeroAndIncrementsOnPluginEvent() {
        let manager = PluginManagingStub()
        let viewModel = PluginManagementViewModel(manager: manager)

        XCTAssertEqual(viewModel.revision, 0)

        manager.send(.listChanged)

        XCTAssertEqual(viewModel.revision, 1)
    }

    func testRevisionIncrementsOnEnabledStateChangedEvent() {
        let manager = PluginManagingStub()
        let viewModel = PluginManagementViewModel(manager: manager)

        manager.send(.enabledStateChanged(pluginID: "a", enabled: true))

        XCTAssertEqual(viewModel.revision, 1)
    }

    func testViewModelSubscribesToManagerExactlyOnce() {
        let manager = PluginManagingStub()

        _ = PluginManagementViewModel(manager: manager)

        XCTAssertEqual(manager.observerCount, 1)
    }

    func testViewModelKeepsManagerReference() {
        let manager = PluginManagingStub()
        let viewModel = PluginManagementViewModel(manager: manager)

        XCTAssertTrue(viewModel.manager === manager)
    }
}
