import XCTest
@testable import FactoryGitOK
import ProviderPluginManaging
import ProviderStorage
import ProviderToolbar

/// 工具栏可见性回归测试。
///
/// 历史缺陷：`DefaultPluginManager()` 无参构造后再 `attach`，内部 controlling
/// 拿不到 kernel，`isEnabled` 对所有插件恒为 false → 共享 PluginToolbar 的
/// 状态同步把全部插件标记为 disabled → `visibleToolbarItems` 按归属过滤掉
/// 所有插件贡献的按钮（OpenFinder、Terminal、Settings 等全部消失）。
/// 此处断言装配后 `PluginManaging.isEnabled` 与内核一致，且插件贡献的
/// 工具栏项仍可见。
@MainActor
final class PluginToolbarVisibilityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let stateFile = DefaultStorageProvider.makeDefaultDataRootDirectory()
            .appendingPathComponent("com.coffic.gitok.plugin.plugin-manager", isDirectory: true)
            .appendingPathComponent("plugin-enabled-overrides.plist", isDirectory: false)
        try? FileManager.default.removeItem(at: stateFile)
    }

    func testPluginManagingReportsKernelEnabledState() throws {
        let kernel = try KernelFactory.makeKernel()
        let manager = try XCTUnwrap(kernel.resolveProvider((any PluginManaging).self))

        // alwaysOn 插件必须报告为启用（历史缺陷下这里恒为 false）。
        XCTAssertTrue(kernel.isPluginEnabled(id: "com.coffic.gitok.plugin.open-finder"))
        XCTAssertTrue(
            manager.isEnabled(id: "com.coffic.gitok.plugin.open-finder"),
            "PluginManaging.isEnabled 必须转发到内核真实启用状态"
        )
    }

    func testPluginToolbarContributionsRemainVisible() throws {
        let kernel = try KernelFactory.makeKernel()
        let toolbar = try XCTUnwrap(kernel.resolveProvider((any ToolbarProviding).self))
        let visibleIDs = Set(toolbar.visibleToolbarItems.map(\.id))

        // 插件贡献的工具栏按钮必须可见（按插件归属过滤不得误杀）。
        XCTAssertTrue(visibleIDs.contains("com.coffic.gitok.plugin.open-finder.button"))
        XCTAssertTrue(visibleIDs.contains("com.coffic.gitok.plugin.settings-button.openSettings"))
        XCTAssertTrue(visibleIDs.contains("com.coffic.gitok.plugin.sidebar-toggle.toggleSidebar"))
        // 宿主直接注入、不归属任何插件的项也必须保留。
        XCTAssertTrue(visibleIDs.contains("workspace-scene-picker"))
    }
}
