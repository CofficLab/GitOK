import SwiftUI

/// Rail（侧边栏）的纵向区块视图（由外部注入）。
///
/// 与 `RailTabItem` 的「标签栏 + 内容区」模式互补：多个插件可以各自贡献
/// 一个 `RailSectionItem`，Rail 视图用 `VStack` 把它们纵向堆叠组合。
/// 区块自身决定高度策略：
/// - 固定高度区块（如工作区状态行）返回固定高度的视图，占其自然高度；
/// - 弹性区块（如 commit 列表）返回 `maxHeight: .infinity`，填满剩余空间。
@MainActor
public struct RailSectionItem: Identifiable {
    public let id: String
    /// 区块在 Rail 中的纵向顺序（升序，小的在上）。
    public let order: Int
    /// 区块视图。
    public let makeView: @MainActor () -> AnyView

    public init<Content: View>(
        id: String,
        order: Int = 200,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.order = order
        self.makeView = { AnyView(content()) }
    }
}
