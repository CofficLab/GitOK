import Combine
import SwiftUI

// MARK: - 根视图提供能力协议

/// 根视图提供能力协议（对齐 Lumi 的 `RootViewProviding`）。
///
/// 根布局（顶部工具栏 + 内容区）由该 provider 持有并组合：
/// - 宿主在装配时通过 `setToolbarView(_:)` 注入工具栏视图（通常来自
///   `GitOKToolbarProviding.makeToolbarView()`）；
/// - 通过 `setContentView(_:)` 注入主内容视图（通常来自 `ContentView`）；
/// - `makeRootView()` 返回「工具栏 + 内容区」的根布局，并延伸到窗口最顶部
///   （fullSizeContentView 下红绿灯悬浮在自绘顶栏左上角）。
///
/// 协议只声明能力，不关心具体实现。使用 `AnyView` 而非 `associatedtype`：
/// 可无泛型约束地作为存在类型（`any GitOKRootViewProviding`）注册进
/// `KernelCoreContainer` 的类型注册表。
@MainActor
public protocol GitOKRootViewProviding: AnyObject, ObservableObject
    where ObjectWillChangePublisher == ObservableObjectPublisher {
    /// 已注入的工具栏视图（`nil` 表示无工具栏）。
    var toolbarView: AnyView? { get }

    /// 已注入的主内容视图（`nil` 表示无内容）。
    var contentView: AnyView? { get }

    /// 注入工具栏视图（传 `nil` 表示无工具栏）。
    func setToolbarView(_ view: AnyView?)

    /// 注入主内容视图（传 `nil` 表示无内容）。
    func setContentView(_ view: AnyView?)

    /// 返回根布局视图（工具栏 + 内容区）。
    func makeRootView() -> AnyView
}

// MARK: - 默认实现

/// `GitOKRootViewProviding` 的默认实现：持有注入的工具栏与内容视图，
/// 组合成「顶部工具栏 + 内容区」的根布局。
@MainActor
public final class DefaultGitOKRootViewProvider: GitOKRootViewProviding, ObservableObject {
    @Published public private(set) var toolbarView: AnyView?
    @Published public private(set) var contentView: AnyView?

    public init() {}

    public func setToolbarView(_ view: AnyView?) {
        toolbarView = view
    }

    public func setContentView(_ view: AnyView?) {
        contentView = view
    }

    public func makeRootView() -> AnyView {
        AnyView(GitOKRootHostView(provider: self))
    }
}

// MARK: - 根布局视图

/// 根布局视图：顶部工具栏 + 内容区。
///
/// `.ignoresSafeArea()` 让整条内容（含自绘顶栏）延伸至窗口最顶部，
/// 红绿灯悬浮在顶栏左上角（顶栏内已预留 76pt 拖拽/交通灯区）。
struct GitOKRootHostView: View {
    @ObservedObject var provider: DefaultGitOKRootViewProvider

    var body: some View {
        VStack(spacing: 0) {
            if let toolbarView = provider.toolbarView {
                toolbarView
                    .zIndex(10)
            }
            if let contentView = provider.contentView {
                contentView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
