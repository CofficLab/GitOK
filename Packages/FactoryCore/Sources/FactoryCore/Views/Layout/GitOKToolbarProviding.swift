import Combine
import GitOKAppCore
import GitOKUI
import KitGitOKCore
import SwiftUI

// MARK: - 工具栏视图提供能力协议

/// 工具栏视图提供能力协议（对齐 Lumi 的 `ToolbarProviding`）。
///
/// 自绘 44pt 顶栏由该 provider 持有并渲染（`makeToolbarView()`）：
/// - leading（红绿灯之后、居中 tab 选择器之前）与 trailing（内容区末尾）
///   工具栏项由插件通过 `setLeadingItems` / `setTrailingItems`（替换）或
///   `addLeadingItem` / `addTrailingItem`（追加，多插件互不覆盖）注入；
/// - 项携带 `order`，同一 placement 内按 order 升序排布；
/// - 宿主把 `makeToolbarView()` 的结果注入到
///   `GitOKRootViewProviding.setToolbarView(_:)` 中。
///
/// 协议只声明能力，不关心具体实现。使用 `AnyView` 而非 `associatedtype`：
/// 可无泛型约束地作为存在类型（`any GitOKToolbarProviding`）注册进
/// `KernelCoreContainer` 的类型注册表。
@MainActor
public protocol GitOKToolbarProviding: AnyObject, ObservableObject
    where ObjectWillChangePublisher == ObservableObjectPublisher {
    /// 工具栏左侧（leading）项：红绿灯预留之后、居中 tab 选择器之前。
    var leadingItems: [GitOKToolbarItem] { get }

    /// 工具栏右侧（trailing）项：内容区末尾。
    var trailingItems: [GitOKToolbarItem] { get }

    /// 工具栏整体是否可见。
    var isToolbarVisible: Bool { get }

    /// 居中 tab 选择器是否可见。
    var isTabPickerVisible: Bool { get }

    /// 项目操作（trailing）项是否可见。
    var isProjectActionsVisible: Bool { get }

    /// 注入工具栏 leading 项（替换当前全部项）。
    func setLeadingItems(_ items: [GitOKToolbarItem])

    /// 注入工具栏 trailing 项（替换当前全部项）。
    func setTrailingItems(_ items: [GitOKToolbarItem])

    /// 追加一条 leading 项（同 id 去重，保留先注册者），并按 order 重排。
    func addLeadingItem(_ item: GitOKToolbarItem)

    /// 追加一条 trailing 项（同 id 去重，保留先注册者），并按 order 重排。
    func addTrailingItem(_ item: GitOKToolbarItem)

    /// 按 id 撤回插件贡献的工具栏项（同时作用于 leading 与 trailing）。
    func removeToolbarItems(ids: Set<String>)

    /// 设置工具栏整体显隐。
    func setToolbarVisible(_ visible: Bool)

    /// 设置居中 tab 选择器显隐。
    func setTabPickerVisible(_ visible: Bool)

    /// 设置项目操作（trailing）项显隐。
    func setProjectActionsVisible(_ visible: Bool)

    /// 返回自绘 44pt 顶栏视图（基于已注入的 items 渲染）。
    func makeToolbarView() -> AnyView
}

// MARK: - 默认实现

/// `GitOKToolbarProviding` 的默认实现：持有 leading/trailing 项与显隐状态，
/// 渲染自绘 44pt 顶栏。项按 `order` 升序排布。
@MainActor
public final class DefaultGitOKToolbarProvider: GitOKToolbarProviding, ObservableObject {
    @Published public private(set) var leadingItems: [GitOKToolbarItem] = []
    @Published public private(set) var trailingItems: [GitOKToolbarItem] = []
    @Published public private(set) var isToolbarVisible = true
    @Published public private(set) var isTabPickerVisible = true
    @Published public private(set) var isProjectActionsVisible = true

    public init() {}

    public func setLeadingItems(_ items: [GitOKToolbarItem]) {
        leadingItems = Self.sorted(items)
    }

    public func setTrailingItems(_ items: [GitOKToolbarItem]) {
        trailingItems = Self.sorted(items)
    }

    public func addLeadingItem(_ item: GitOKToolbarItem) {
        guard !leadingItems.contains(where: { $0.id == item.id }) else { return }
        leadingItems = Self.sorted(leadingItems + [item])
    }

    public func addTrailingItem(_ item: GitOKToolbarItem) {
        guard !trailingItems.contains(where: { $0.id == item.id }) else { return }
        trailingItems = Self.sorted(trailingItems + [item])
    }

    public func removeToolbarItems(ids: Set<String>) {
        leadingItems = Self.sorted(leadingItems.filter { !ids.contains($0.id) })
        trailingItems = Self.sorted(trailingItems.filter { !ids.contains($0.id) })
    }

    public func setToolbarVisible(_ visible: Bool) {
        guard isToolbarVisible != visible else { return }
        isToolbarVisible = visible
    }

    public func setTabPickerVisible(_ visible: Bool) {
        guard isTabPickerVisible != visible else { return }
        isTabPickerVisible = visible
    }

    public func setProjectActionsVisible(_ visible: Bool) {
        guard isProjectActionsVisible != visible else { return }
        isProjectActionsVisible = visible
    }

    public func makeToolbarView() -> AnyView {
        AnyView(GitOKToolbarView(provider: self))
    }

    /// 按 `order` 升序稳定排序（同 order 保持原相对顺序）。
    private static func sorted(_ items: [GitOKToolbarItem]) -> [GitOKToolbarItem] {
        items.enumerated().sorted { lhs, rhs in
            if lhs.element.order != rhs.element.order {
                return lhs.element.order < rhs.element.order
            }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }
}

// MARK: - 自绘顶栏视图

/// 自绘 44pt 顶栏视图：取代系统原生统一工具栏，跨 macOS 版本外观统一。
///
/// 布局与 Lumi 的 `ToolbarView` 一致：红绿灯预留 76pt、整条可作为窗口
/// 拖拽区、中心标签页选择器绝对居中。
///
/// 渲染由 toolbar provider 驱动；交互使用环境对象 `AppVM` / `ProjectVM`
/// 与 `@GitOKTheme`（均由根视图注入，provider 自身不依赖视图树位置）。
struct GitOKToolbarView: View {
    @ObservedObject var provider: DefaultGitOKToolbarProvider
    @EnvironmentObject var app: AppVM
    @EnvironmentObject var vm: ProjectVM
    @GitOKTheme private var theme

    var body: some View {
        ZStack {
            WindowDragRegion()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 8) {
                // 红绿灯预留：hiddenTitleBar 下红绿灯悬浮于左上角，
                // 顶栏项从此宽度之后开始排布（与 Lumi 一致）。
                Color.clear
                    .frame(width: 76, height: 44)
                    .accessibilityHidden(true)

                sidebarToggleButton

                if let sidebarToolbarItem = GitOKFactoryChrome.sidebarToolbarItem {
                    sidebarToolbarItem
                }

                ForEach(provider.leadingItems) { item in
                    item.view
                }

                Spacer(minLength: 12)

                if vm.project != nil, provider.isProjectActionsVisible {
                    ForEach(provider.trailingItems) { item in
                        item.view
                    }
                }
            }
            .padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 标签页选择器绝对居中，maxWidth 420，左右预留红绿灯空间。
            if provider.isTabPickerVisible, AppTabCatalog.visibleTabs.count > 1 {
                Picker(String(localized: "Select Tab"), selection: tabBinding) {
                    ForEach(AppTabCatalog.visibleTabs) { workspaceTab in
                        Text(workspaceTab.displayName).tag(workspaceTab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                .padding(.horizontal, 88)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(theme.appToolbarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.appDivider)
                .frame(height: 1)
        }
        .foregroundStyle(theme.textPrimary)
    }

    /// tab 选择器绑定：读写 `AppVM.currentTab`（单一数据源，同时持久化）。
    private var tabBinding: Binding<GitOKAppTab> {
        Binding(
            get: { app.currentTab },
            set: { app.setTab($0) }
        )
    }

    /// 侧栏切换按钮：原生 NavigationSplitView 自带切换在自绘顶栏下不再显示，
    /// 这里补充同等能力的入口。
    private var sidebarToggleButton: some View {
        Button {
            app.setSidebarVisibility(!app.sidebarVisibility, reason: "topToolbarToggle")
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help(String(localized: "Toggle Sidebar"))
        .foregroundStyle(theme.textPrimary)
    }
}
