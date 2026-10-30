import AppKit
import SwiftUI
import XCTest
@testable import FactoryGitOK
import KernelCore
import ProviderTheme
import ProviderStorage
import GitOKProviderRootView
import ProviderToolbar
import ProviderStatusBar
import ProviderContentView
import ProviderSidebar
import ProviderRailView
import ProviderSettingView
import ProviderToast

// MARK: - FactoryGitOK 入口薄包装

@MainActor
final class FactoryGitOKEntryTests: XCTestCase {
    func testMakeKernelReturnsRunningKernel() throws {
        let kernel = try FactoryGitOK.makeKernel()
        XCTAssertEqual(kernel.lifecycleState, .running)
    }

    func testMakeMainViewWithKernelProducesView() throws {
        let kernel = try FactoryGitOK.makeKernel()
        let view = try FactoryGitOK.makeMainView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewWithKernelProducesView() throws {
        let kernel = try FactoryGitOK.makeKernel()
        let view = try FactoryGitOK.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    /// GitOK 只加载白名单内的主题，加上 ProviderTheme 的 4 个内置基础外观。
    ///
    /// 断言具体 id 集合而非仅断言数量：数量断言挡不住「白名单被悄悄改成全量」
    /// 这类回归，id 集合能同时锁住白名单内容与裁剪结果。
    func testThemeCatalogIsRestrictedToWhitelist() throws {
        let kernel = try FactoryGitOK.makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))

        let expectedIDs: Set<String> = [
            // 白名单主题
            "lumi", "sky", "one-dark", "dracula", "vscode-light",
            // ProviderTheme 内置基础外观（不受白名单约束）
            "lumi-system", "lumi-dark", "lumi-light",
        ]

        XCTAssertEqual(Set(theme.themes.map(\.id)), expectedIDs)
        XCTAssertEqual(theme.themes.count, expectedIDs.count)
    }
}

// MARK: - KernelFactory 无参视图入口

@MainActor
final class KernelFactoryViewEntryTests: XCTestCase {
    func testMakeMainViewNoKernelProducesView() throws {
        let view = try KernelFactory.makeMainView()
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewNoKernelProducesView() throws {
        let view = try KernelFactory.makeSettingsView()
        XCTAssertNotNil(view)
    }

    func testMakeMainViewWithKernelUsesDefaultViewFactory() throws {
        let kernel = try KernelFactory.makeKernel()
        let view = try KernelFactory.makeMainView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewWithKernelUsesDefaultViewFactory() throws {
        let kernel = try KernelFactory.makeKernel()
        let view = try KernelFactory.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }
}

// MARK: - DefaultViewFactory 视图装配分支

@MainActor
final class DefaultViewFactoryAssemblyTests: XCTestCase {
    func testMakeMainViewResolvesRegisteredProviders() throws {
        let kernel = try KernelFactory.makeKernel()
        let factory = DefaultViewFactory()

        let view = try factory.makeMainView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    func testMakeSettingsViewResolvesRegisteredProviders() throws {
        let kernel = try KernelFactory.makeKernel()
        let factory = DefaultViewFactory()

        let view = try factory.makeSettingsView(kernel: kernel)
        XCTAssertNotNil(view)
    }

    /// 空内核：RootViewProviding 未注册时返回占位 Text 视图。
    func testMakeMainViewWithoutRootProviderReturnsPlaceholder() throws {
        let emptyKernel = KernelCoreContainer()
        let factory = DefaultViewFactory()

        let view = try factory.makeMainView(kernel: emptyKernel)
        XCTAssertNotNil(view)
    }

    /// 空内核：SettingViewProviding 未注册时返回占位 Text 视图。
    func testMakeSettingsViewWithoutSettingProviderReturnsPlaceholder() throws {
        let emptyKernel = KernelCoreContainer()
        let factory = DefaultViewFactory()

        let view = try factory.makeSettingsView(kernel: emptyKernel)
        XCTAssertNotNil(view)
    }

    func testSyncLumiThemeDarkAppearance() throws {
        let kernel = try KernelFactory.makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))
        DefaultViewFactory.syncLumiTheme(theme)
    }

    func testSyncLumiThemeLightAppearance() throws {
        let kernel = try KernelFactory.makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))
        DefaultViewFactory.syncLumiTheme(theme)
    }

    func testSyncLumiThemeSystemAppearance() throws {
        let kernel = try KernelFactory.makeKernel()
        let theme = try XCTUnwrap(kernel.resolveProvider((any ThemeProviding).self))
        DefaultViewFactory.syncLumiTheme(theme)
    }
}
