import XCTest
@testable import GitOK
import GitOKPluginRootView
import KernelCore
import ProviderGit
import ProviderRootView
import ProviderStorage
import ProviderTheme
import ProviderToolbar
import ProviderWorkspaceScene

#if os(macOS)
import ProviderRailView
import ProviderSidebar
import ProviderStatusBar
#endif

/// GitOKHostManifest 集成测试：共享装配引擎解释清单后的真实内核基线。
@MainActor
final class GitOKHostManifestTests: GitOKKernelTestCase {

    /// 清单装配的内核：宿主根视图 + 全部视图接线 + 工作区门控就位。
    func testManifestBootsWiredKernel() async throws {
        let kernel = try await makeKernel()

        let root = try XCTUnwrap(
            kernel.resolveProvider((any RootViewProviding).self) as? GitOKRootViewProvider
        )
        XCTAssertNotNil(root.view(for: .toolbar))
        XCTAssertNotNil(root.view(for: .content))
        XCTAssertNotNil(root.view(for: .sidebar))
        XCTAssertNotNil(root.view(for: .rail))
        XCTAssertNotNil(root.view(for: .statusBar))

        // RootViewPlugin 接管宿主 Provider 并完成门控（无项目 → noProject）。
        XCTAssertEqual(root.workspaceState, .noProject)

        // App 域 Provider 钩子注册的基线外能力。
        XCTAssertEqual(
            kernel.resolveProvider((any WorkspaceSceneProviding).self)?.currentScene,
            .git
        )
        XCTAssertNotNil(kernel.resolveProvider((any GitProviding).self))
        XCTAssertTrue(
            kernel.resolveProvider((any ToolbarProviding).self)?.toolbarItems.contains {
                $0.id == "workspace-scene-picker"
            } == true
        )
        // GitOK 自带设置按钮插件，不使用共享工具栏设置按钮（id "settings"）。
        XCTAssertFalse(
            kernel.resolveProvider((any ToolbarProviding).self)?.toolbarItems.contains {
                $0.id == "settings"
            } == true
        )
    }

    /// 主题选择持久化到 GitOK 历史的插件数据目录，重启后延续。
    func testThemeSelectionPersistsInPluginDataDirectory() async throws {
        let kernel = try await makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))
        try theme.selectTheme(id: "dracula")

        let storage = try XCTUnwrap(kernel.resolveProvider((any StorageProviding).self))
        let selectionFile = storage.pluginDataDirectory(for: "com.coffic.gitok.plugin.theme-pack")
            .appendingPathComponent("theme-selection.plist")
        // saveSelection 经 Task.detached 异步落盘，等待写入完成。
        let deadline = Date().addingTimeInterval(2)
        while !FileManager.default.fileExists(atPath: selectionFile.path), Date() < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: selectionFile.path))

        // 同一数据根再次装配：用户选择延续（setStorageDirectory 钩子生效）。
        let rebooted = try await makeKernel()
        XCTAssertEqual(
            rebooted.resolveProvider((any ThemeProviding).self)?.selectedThemeId,
            "dracula"
        )
    }
}