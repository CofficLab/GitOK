import Combine
import SwiftUI

/// 主内容视图提供能力协议
///
/// 定义「内核 → 主内容区」这一段的最小契约：多个插件（如 Commit Form、
/// Commit Detail）在 `onBoot` 中解析 `ContentViewProviding`，通过
/// `addContentView(_:id:order:)` 注册自己的内容块；`makeContentView()` 把
/// 全部内容块按 `order` 升序自上而下组成一个 `VStack` 返回，RootView 的
/// 内容区据此渲染。
///
/// 每个插件负责注册 / 移除属于自己的内容块（以唯一 `id` 标识），不应清空
/// 其他插件的内容。未注册任何内容块时回退到占位视图。
///
/// 协议只声明能力，不关心具体实现。
///
/// 使用 `AnyView` 而非 `associatedtype`：协议可无泛型约束地作为存在类型
/// （`any ContentViewProviding`）注册进 KernelCore 的 `[ObjectIdentifier: Any]` 注册表。
@MainActor
public protocol ContentViewProviding: AnyObject, ObservableObject
    where ObjectWillChangePublisher == ObservableObjectPublisher {
    /// 注册一块主内容区；同一 `id` 重复注册会覆盖旧内容。`order` 越小越靠上。
    func addContentView(_ view: AnyView, id: String, order: Int)

    /// 移除指定 `id` 的内容块。
    func removeContentView(id: String)

    /// 移除全部内容块（回退到占位视图）。
    func removeAllContentView()

    /// 返回当前全部内容块按 `order` 升序组成的 VStack；未注册任何内容块时返回占位视图。
    func makeContentView() -> AnyView

}
