import LumiThemePack
import AppKit
import SwiftUI
import XCTest
@testable import FactoryGitOK
import KernelCore
import ProviderTheme
import LumiUI
import ProviderStorage
import ProviderSettingView
import ProviderLogo
import ProviderSidebar
import ProviderRailView
import ProviderCommand
import ProviderPluginManaging
import ProviderContentView
import ProviderDocsView
import ProviderToolbar
import ProviderStatusBar
import GitOKProviderRootView
import ProviderToast
import ProviderWorkspaceScene

// MARK: - KernelFactory 行为

@MainActor
final class KernelFactoryTests: XCTestCase {

    private final class MarkerPlugin: SuperPlugin {
        let id = "marker"
        let metadata = PluginMetadata(id: "marker", policy: .disabledByDefault)
    }

    private final class MockViewFactory: ViewFactory {
        var makeMainViewCallCount = 0
        var makeSettingsViewCallCount = 0

        func makeMainView(kernel: KernelCoreContainer) throws -> AnyView {
            makeMainViewCallCount += 1
            return AnyView(EmptyView())
        }

        func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
            makeSettingsViewCallCount += 1
            return AnyView(EmptyView())
        }
    }

    func testMakeKernelBootsAdditionalPlugins() throws {
        let kernel = try KernelFactory.makeKernel(additionalPlugins: [MarkerPlugin()])

        XCTAssertTrue(kernel.isPluginRegistered(id: "marker"))
        XCTAssertEqual(kernel.lifecycleState, .running)
    }

    func testMakeKernelPropagatesDuplicateProviderError() throws {
        @MainActor
        struct DuplicateProviderFactory: ProviderFactory {
            let inner = DefaultProviderFactory()

            func makeStorageProvider() -> any StorageProviding { inner.makeStorageProvider() }
            func makeWorkspaceSceneProvider() -> any WorkspaceSceneProviding { inner.makeWorkspaceSceneProvider() }
            func makeThemeProvider() -> any ThemeProviding { inner.makeThemeProvider() }
            func makeContentViewProvider() -> any ContentViewProviding { inner.makeContentViewProvider() }
            func makeDocsViewProvider() -> any DocsViewProviding { inner.makeDocsViewProvider() }
            func makeToolbarProvider() -> any ToolbarProviding { inner.makeToolbarProvider() }
            func makeStatusBarProvider() -> any StatusBarProviding { inner.makeStatusBarProvider() }
            func makeRootViewProvider() -> any RootViewProviding { inner.makeRootViewProvider() }
            func makeLogoProvider() -> any LogoProviding { inner.makeLogoProvider() }
            func makeSidebarProvider() -> any SidebarProviding { inner.makeSidebarProvider() }
            func makeRailViewProvider() -> any RailViewProviding { inner.makeRailViewProvider() }
            func makeCommandProvider() -> any CommandProviding { inner.makeCommandProvider() }
            func makeToastProvider() -> any ToastProviding { inner.makeToastProvider() }
            func makePluginManagingProvider(kernel: KernelCoreContainer) -> any PluginManaging {
                inner.makePluginManagingProvider(kernel: kernel)
            }
            func makeSettingViewProvider() -> any SettingViewProviding { inner.makeSettingViewProvider() }

            func registerProviders(into kernel: KernelCoreContainer) throws {
                try inner.registerProviders(into: kernel)
                // 重复注册 StorageProviding → providerAlreadyRegistered。
                try kernel.registerProvider((any StorageProviding).self, inner.makeStorageProvider())
            }
        }

        XCTAssertThrowsError(try KernelFactory.makeKernel(
            providerFactory: DuplicateProviderFactory(),
            pluginFactory: DefaultPluginFactory()
        )) { error in
            guard case KernelCoreError.providerAlreadyRegistered = error else {
                return XCTFail("期望 providerAlreadyRegistered，得到 \(error)")
            }
        }
    }

    func testMakeMainViewDelegatesToViewFactory() throws {
        let kernel = try KernelFactory.makeKernel()
        let viewFactory = MockViewFactory()

        _ = try KernelFactory.makeMainView(kernel: kernel, viewFactory: viewFactory)

        XCTAssertEqual(viewFactory.makeMainViewCallCount, 1)
        XCTAssertEqual(viewFactory.makeSettingsViewCallCount, 0)
    }

    func testMakeSettingsViewDelegatesToViewFactory() throws {
        let kernel = try KernelFactory.makeKernel()
        let viewFactory = MockViewFactory()

        _ = try KernelFactory.makeSettingsView(kernel: kernel, viewFactory: viewFactory)

        XCTAssertEqual(viewFactory.makeSettingsViewCallCount, 1)
        XCTAssertEqual(viewFactory.makeMainViewCallCount, 0)
    }

    /// 设置窗口默认选中规则（回归测试）：全新启动后应选中 order 最小的入口。
    ///
    /// 背景：`addEntries` 会走 `registerEntries`，其"选中为空则锁定为当时列表
    /// 第一个"的语义会让**最先注册入口的插件**意外成为默认选中（Wakey/Lumi
    /// 均已踩坑并在各自内核启动后重置），本测试验证 GitOK 是否存在同样问题。
    func testSettingsDefaultsToFirstEntryByOrder() throws {
        let kernel = try KernelFactory.makeKernel()
        let settings = try XCTUnwrap(kernel.resolveProvider((any SettingViewProviding).self))

        XCTAssertFalse(settings.entries.isEmpty, "设置入口应在内核启动后完成注册")
        let orders = settings.entries.map(\.order)
        XCTAssertEqual(orders, orders.sorted(), "entries must be sorted by order ascending")

        print("GITOK-ENTRIES: \(settings.entries.map { "\($0.id)#\($0.order)" }.joined(separator: ", "))")
        print("GITOK-SELECTED: \(settings.selectedEntryID ?? "nil")")

        XCTAssertEqual(
            settings.selectedEntryID, settings.entries.first?.id,
            "默认应选中 \(settings.entries.first?.id ?? "nil")，实际为 \(settings.selectedEntryID ?? "nil")"
        )
    }
}

// MARK: - LumiPaletteChromeTheme 适配器

@MainActor
final class PaletteChromeThemeTests: XCTestCase {

    private func makeChromeTheme(
        source: ProviderTheme.LumiTheme = BuiltinThemes.system,
        colorScheme: ColorScheme = ColorScheme.light
    ) -> LumiPaletteChromeTheme {
        LumiPaletteChromeTheme(theme: source, colorScheme: colorScheme)
    }

    func testIdentityFieldsMapThrough() {
        let theme = makeChromeTheme(source: BuiltinThemes.dark)

        XCTAssertEqual(theme.identifier, "lumi-dark")
        XCTAssertEqual(theme.displayName, BuiltinThemes.dark.displayName)
        XCTAssertEqual(theme.compactName, BuiltinThemes.dark.compactName)
        XCTAssertEqual(theme.description, BuiltinThemes.dark.description)
        XCTAssertEqual(theme.iconName, "moon.fill")
    }

    func testAppearanceKindMapping() {
        let themes: [(ProviderTheme.LumiTheme, LumiUI.ThemeAppearanceKind)] = [
            (BuiltinThemes.dark, LumiUI.ThemeAppearanceKind.dark),
            (BuiltinThemes.light, LumiUI.ThemeAppearanceKind.light),
            (BuiltinThemes.system, LumiUI.ThemeAppearanceKind.system),
        ]
        for (source, expected) in themes {
            XCTAssertEqual(makeChromeTheme(source: source).appearanceKind, expected, "source=\(source.id)")
        }
    }

    func testSemanticColorGroupsResolve() {
        let theme = makeChromeTheme(source: BuiltinThemes.lumi, colorScheme: ColorScheme.dark)

        let accent = theme.accentColors()
        let atmosphere = theme.atmosphereColors()
        let glow = theme.glowColors()

        for color in [accent.primary, accent.secondary, accent.tertiary,
                      atmosphere.deep, atmosphere.medium, atmosphere.light,
                      glow.subtle, glow.medium, glow.intense,
                      theme.workspaceTextColor(),
                      theme.workspaceSecondaryTextColor(),
                      theme.workspaceTertiaryTextColor(),
                      theme.sidebarBackgroundColor(),
                      theme.sidebarSelectionColor(),
                      theme.sidebarSelectionTextColor(),
                      theme.statusBarForegroundColor(),
                      theme.statusBarDividerColor(),
                      theme.statusBarItemBackgroundColor(isPresented: true),
                      theme.statusBarItemBackgroundColor(isPresented: false),
                      theme.statusBarItemForegroundColor(),
                      theme.iconColor] {
            XCTAssertNotNil(NSColor(color).usingColorSpace(.sRGB), "color should resolve for \(color)")
        }
    }

    func testColorSchemeChangesResolvedColors() {
        let lightTheme = makeChromeTheme(source: BuiltinThemes.lumi, colorScheme: ColorScheme.light)
        let darkTheme = makeChromeTheme(source: BuiltinThemes.lumi, colorScheme: ColorScheme.dark)

        let lightColor = NSColor(lightTheme.sidebarBackgroundColor()).usingColorSpace(.sRGB)
        let darkColor = NSColor(darkTheme.sidebarBackgroundColor()).usingColorSpace(.sRGB)
        // 明暗两种外观下背景色应可解析且不同。
        XCTAssertNotNil(lightColor)
        XCTAssertNotNil(darkColor)
        XCTAssertNotEqual(lightColor?.hexDescription, darkColor?.hexDescription)
    }
}

private extension NSColor {
    var hexDescription: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "" }
        return String(format: "#%02X%02X%02X",
                      Int(round(rgb.redComponent * 255)),
                      Int(round(rgb.greenComponent * 255)),
                      Int(round(rgb.blueComponent * 255)))
    }
}
