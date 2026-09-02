import Foundation
import KernelCore
import LumiUI
import ProviderSettingView
import XCTest
@testable import PluginPluginManager

@MainActor
final class PluginManagerPluginTests: XCTestCase {
    /// 简单可配置插件（policy 可开关）。
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

    func testOnBootRegistersPluginsSettingEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)

        let plugin = PluginManagerPlugin()
        try plugin.onBoot(kernel: kernel)

        XCTAssertTrue(settings.entries.contains { $0.id == "plugins" })
    }

    func testOnShutdownRemovesPluginsSettingEntry() throws {
        let kernel = KernelCoreContainer()
        let settings = DefaultSettingViewProviding()
        try kernel.registerProvider((any SettingViewProviding).self, settings)

        let plugin = PluginManagerPlugin()
        try plugin.onBoot(kernel: kernel)
        try plugin.onShutdown(kernel: kernel)

        XCTAssertFalse(settings.entries.contains { $0.id == "plugins" })
    }

    func testPluginRowModelReflectsKernelEnabledState() throws {
        let kernel = KernelCoreContainer()
        let toggleable = ToggleablePlugin()
        let required = RequiredPlugin()
        try kernel.registerPlugin(toggleable)
        try kernel.registerPlugin(required)

        let toggleableRow = PluginRowModel(plugin: toggleable, kernel: kernel)
        let requiredRow = PluginRowModel(plugin: required, kernel: kernel)

        XCTAssertFalse(toggleableRow.isLocked)
        XCTAssertTrue(requiredRow.isLocked)
        // 默认启用（enabledByDefault / alwaysOn）。
        XCTAssertTrue(toggleableRow.isEnabled)
        XCTAssertTrue(requiredRow.isEnabled)
    }

    func testPluginRowModelCategoryIcon() {
        XCTAssertEqual(PluginRowModel.systemImage(for: .project), "folder")
        XCTAssertEqual(PluginRowModel.systemImage(for: .system), "gearshape")
        XCTAssertEqual(PluginRowModel.systemImage(for: .integration), "link")
    }
}
