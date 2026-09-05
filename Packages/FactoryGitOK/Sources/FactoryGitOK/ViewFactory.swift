import Foundation
import KernelCore
import LumiUI
import ProviderContentView
import ProviderRootView
import ProviderSettingView
import ProviderStatusBar
import ProviderTheme
import ProviderToolbar
import SwiftUI

#if os(macOS)
import ProviderRailView
import ProviderSidebar
#endif

/// 默认 `ViewFactory` 实现：使用内核已注册的 Provider 组装主视图与设置视图。
///
/// 视图组装逻辑（工具栏 / 侧边栏 / Rail / 内容区注入、LumiUI 主题桥接）
/// 集中在此；`KernelFactory.makeMainView(kernel:)` 等入口
/// 委托本实现，宿主可通过自定义 `ViewFactory` 覆盖视图组装行为。
@MainActor
public struct DefaultViewFactory: ViewFactory {
    public init() {}

    /// 使用已装配的内核组装完整主视图（工具栏 + 侧边栏 + Rail + 内容区）。
    public func makeMainView(kernel: KernelCoreContainer) throws -> AnyView {
        guard let rootView = kernel.resolveProvider((any RootViewProviding).self) else {
            return AnyView(Text(LumiPluginLocalization.string("RootViewProviding not registered", bundle: .module)))
        }

        // ProviderTheme and LumiUI are separate layers. Resolve the selected
        // theme before constructing injected views so SwiftUI semantic colors
        // (.primary/.secondary) and AppKit controls see the same appearance
        // on their first render.
        if let theme = kernel.resolveProvider((any ThemeProviding).self) {
            Self.syncLumiTheme(theme)
        }

        if let toolbar = kernel.resolveProvider((any ToolbarProviding).self) {
            rootView.setToolbarView(toolbar.makeToolbarView())
        }
        if let statusBar = kernel.resolveProvider((any StatusBarProviding).self) {
            rootView.setStatusBarView(statusBar.makeStatusBarView())
        }
        #if os(macOS)
        if let sidebar = kernel.resolveProvider((any SidebarProviding).self) {
            rootView.setSidebarView(sidebar.makeSidebarView())
        }
        if let rail = kernel.resolveProvider((any RailViewProviding).self) {
            rootView.setRailView(rail.makeRailView())
            rootView.setRailViewVisible(rail.hasVisibleTabs || rail.hasVisibleSections)
            rootView.bindRailViewVisibility(to: rail.railVisibilityPublisher)
            rootView.bindRailViewWidth(
                to: rail.railWidthPublisher,
                onResize: rail.saveCurrentWidth
            )
        }
        #endif
        if let contentView = kernel.resolveProvider((any ContentViewProviding).self) {
            rootView.setContentView(contentView.makeContentView())
        }
        return themed(rootView.makeRootView(), kernel: kernel)
    }

    /// 使用已装配的内核返回设置视图（共享内核时使用）。
    public func makeSettingsView(kernel: KernelCoreContainer) throws -> AnyView {
        guard let settings = kernel.resolveProvider((any SettingViewProviding).self) else {
            return AnyView(Text(LumiPluginLocalization.string("SettingViewProviding not registered", bundle: .module)))
        }

        // 先把选中主题桥接到 LumiUI 主题体系，避免首帧渲染时 LumiUI 组件
        // （@LumiTheme / ChromeThemes）读到未配置的默认主题而闪烁。
        if let theme = kernel.resolveProvider((any ThemeProviding).self) {
            Self.syncLumiTheme(theme)
        }

        return themed(settings.makeSettingView(), kernel: kernel)
    }

    // MARK: - LumiUI Theme Bridging

    /// 把 `ThemeProviding` 选中的主题桥接到 LumiUI 主题体系（`@LumiTheme` /
    /// `ChromeThemes`），使 LumiUI 组件渲染出与旧版 Lumi 完全一致的颜色。
    static func syncLumiTheme(_ provider: any ThemeProviding) {
        guard let selected = provider.selectedTheme else { return }
        let colorScheme: ColorScheme
        switch selected.appearanceKind {
        case .dark:
            colorScheme = .dark
        case .light:
            colorScheme = .light
        case .system:
            colorScheme = SystemAppearanceResolver.effectiveColorScheme
        }

        // `LumiUITheme.preferredColorScheme` is consumed by the root view and
        // by AppKit appearance bridges. Keep its system value in sync with the
        // ProviderTheme selection instead of leaving the bootstrap `.light`
        // value in place.
        ResolvedSystemColorScheme.current = colorScheme

        let chrome = PaletteChromeTheme(theme: selected, colorScheme: colorScheme)
        ActiveChromeTheme.current = chrome
        LumiUIThemeStore.shared.setTheme(ChromeToUIThemeAdapter(chrome: chrome))
    }

    // MARK: - Theme Application

    /// 用当前选中主题包装视图：明暗外观（`preferredColorScheme`）+ 背景色。
    private func themed(_ view: AnyView, kernel: KernelCoreContainer) -> AnyView {
        guard let theme = kernel.resolveProvider((any ThemeProviding).self) else {
            return view
        }
        return AnyView(ThemeHostingView(theme: theme, content: view))
    }
}

/// 主题感知的视图包装：根据 `ThemeProviding` 的选中主题应用
/// 明暗外观与窗口背景色。
@MainActor
private struct ThemeHostingView<Content: View>: View {
    let theme: any ThemeProviding
    let content: Content

    @StateObject private var themeObservation: ThemeObservationModel
    @State private var refreshTick = false

    init(theme: any ThemeProviding, content: Content) {
        self.theme = theme
        self.content = content
        _themeObservation = StateObject(wrappedValue: ThemeObservationModel(theme: theme))
    }

    var body: some View {
        content
            .preferredColorScheme(preferredColorScheme)
            .background(backgroundColor)
            .onAppear { DefaultViewFactory.syncLumiTheme(theme) }
            .onReceive(themeObservation.$revision) { _ in
                // 主题切换后强制 body 重算，应用新的明暗与背景，
                // 并把新主题桥接到 LumiUI 主题体系（@LumiTheme / ChromeThemes）。
                refreshTick.toggle()
                DefaultViewFactory.syncLumiTheme(theme)
            }
    }

    private var preferredColorScheme: ColorScheme? {
        switch theme.selectedTheme?.appearanceKind ?? .system {
        case .dark: return .dark
        case .light: return .light
        case .system: return ResolvedSystemColorScheme.current
        }
    }

    private var backgroundColor: Color {
        guard let selected = theme.selectedTheme else {
            return Color(nsColor: .windowBackgroundColor)
        }

        let colorScheme: ColorScheme
        switch selected.appearanceKind {
        case .dark:
            colorScheme = .dark
        case .light:
            colorScheme = .light
        case .system:
            colorScheme = ResolvedSystemColorScheme.current
        }
        return selected.palette.backgroundMedium.color(colorScheme: colorScheme)
    }
}

@MainActor
private final class ThemeObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ThemeProvidingObserverHandle)?

    init(theme: any ThemeProviding) {
        handle = theme.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }
}
