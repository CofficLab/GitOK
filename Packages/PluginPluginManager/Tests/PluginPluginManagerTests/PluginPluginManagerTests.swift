import Foundation
import KernelCore
import LumiUI
import ProviderDocsView
import ProviderPluginManaging
import ProviderSettingView
import XCTest
@testable import PluginPluginManager

@MainActor
final class PluginPluginManagerTests: XCTestCase {
    /// 可配置测试插件。
    @MainActor
    private final class ToggleablePlugin: SuperPlugin {
        let id = "test.toggleable"
        var order: Int { 50 }
        var metadata: PluginMetadata {
            PluginMetadata(
                id: id,
                name: "Toggleable",
                description: "A toggleable test plugin",
                category: .project,
                stage: .stable,
                policy: .enabledByDefault
            )
        }
    }

    /// 固定插件（policy 不可开关）。
    @MainActor
    private final class RequiredPlugin: SuperPlugin {
        let id = "test.required"
        var order: Int { 10 }
        var metadata: PluginMetadata {
            PluginMetadata(
                id: id,
                name: "Required",
                description: "A required test plugin",
                category: .core,
                stage: .stable,
                policy: .alwaysOn
            )
        }
    }

    func testOnBootRegistersPluginManagerEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)

        // PluginManaging 未注册：应优雅降级（不注入入口、不崩溃）。
        let plugin = PluginPluginManager()
        try plugin.onBoot(kernel: kernel)
        XCTAssertFalse(settings.entries.contains { $0.id == PluginPluginManager.settingsEntryID })

        // 注册 PluginManaging 后注入入口。
        let manager = DefaultPluginManager(kernel: kernel)
        try kernel.registerProvider((any PluginManaging).self, manager)
        try plugin.onBoot(kernel: kernel)
        XCTAssertTrue(settings.entries.contains { $0.id == PluginPluginManager.settingsEntryID })
    }

    func testOnShutdownRemovesPluginManagerEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)
        let manager = DefaultPluginManager(kernel: kernel)
        try kernel.registerProvider((any PluginManaging).self, manager)

        let plugin = PluginPluginManager()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)
        XCTAssertFalse(settings.entries.contains { $0.id == PluginPluginManager.settingsEntryID })
    }

    func testOnReadyGeneratesAboutForPluginsWithoutAbout() throws {
        let kernel = KernelCoreContainer()
        let docs = DefaultDocsViewProviding()
        try kernel.registerProvider((any DocsViewProviding).self, docs)

        let toggleable = ToggleablePlugin()
        try kernel.registerPlugin(toggleable)

        let plugin = PluginPluginManager()
        try plugin.onReady(kernel: kernel)
        XCTAssertTrue(docs.aboutEntries.contains { $0.id == toggleable.id })
    }

    func testCategoryDisplayMapping() {
        XCTAssertEqual(PluginCategory.project.displayName, "项目")
        XCTAssertEqual(PluginCategory.project.systemImage, "folder")
        XCTAssertEqual(PluginCategory.displayOrder.first, .core)
    }

    func testStageDisplayMapping() {
        XCTAssertEqual(PluginStage.preview.displayName, "预览")
        XCTAssertEqual(PluginStage.stable.displayName, "稳定")
    }
}
