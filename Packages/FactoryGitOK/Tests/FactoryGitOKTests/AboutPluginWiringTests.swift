import XCTest
@testable import FactoryGitOK
import ProviderSettingView
import ProviderStorage

/// 「关于」入口的装配测试。
///
/// 验证共享远程包 `LumiPluginAbout` 在 GitOK 的真实内核里成功注册了
/// 「关于」设置入口——这同时覆盖了「远程依赖可解析」「插件可装配」
/// 「入口确实出现在设置界面」三件事。
@MainActor
final class AboutPluginWiringTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let stateFile = DefaultStorageProvider.makeDefaultDataRootDirectory()
            .appendingPathComponent("com.coffic.gitok.plugin.plugin-manager", isDirectory: true)
            .appendingPathComponent("plugin-enabled-overrides.plist", isDirectory: false)
        try? FileManager.default.removeItem(at: stateFile)
    }

    /// 内核启动后，设置 Provider 上应出现 id 为 `about` 的入口。
    func testAboutEntryIsRegistered() throws {
        let kernel = try KernelFactory.makeKernel()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        let entry = settings.entries.first { $0.id == "about" }
        XCTAssertNotNil(entry, "the shared about plugin should contribute the 'about' settings entry")
    }

    /// 入口标题应为「关于」，且图标是 info.circle。
    func testAboutEntryTitleAndIcon() throws {
        let kernel = try KernelFactory.makeKernel()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        let entry = try XCTUnwrap(settings.entries.first { $0.id == "about" })
        XCTAssertEqual(entry.title, "关于")
        XCTAssertEqual(entry.systemImage, "info.circle")
    }

    /// 「关于」插件本身应处于启用状态（policy 为 alwaysOn）。
    func testAboutPluginIsEnabled() throws {
        let kernel = try KernelFactory.makeKernel()
        XCTAssertTrue(kernel.isPluginEnabled(id: "com.coffic.gitok.plugin.about"))
    }
}
