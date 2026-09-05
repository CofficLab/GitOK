import Combine
import SwiftUI

/// 侧边栏视图提供能力协议
///
/// 定义「内核 → 侧边栏」这一段的最小契约：宿主在启动时通过内核解析
/// `SidebarProviding`，拿到侧边栏视图后放置到窗口左侧。
///
/// 协议只声明能力，不关心具体实现：
/// - 外部通过 `registerItems(_:)` 注入 `SidebarItem`（列表入口）；
/// - 实现负责把注入的 items 渲染成侧边栏视图（`makeSidebarView()`）。
///
/// 使用 `AnyView` 而非 `associatedtype`：协议可无泛型约束地作为存在类型
/// （`any SidebarProviding`）注册进 KernelCore 的 `[ObjectIdentifier: Any]` 注册表。
@MainActor
public protocol SidebarProviding: AnyObject, ObservableObject
    where ObjectWillChangePublisher == ObservableObjectPublisher {
    /// 当前已注入的全部侧边栏项。
    var items: [SidebarItem] { get }

    /// 当前激活入口；无入口时为 nil。
    var activeItemID: String? { get }

    /// 注入侧边栏项（替换当前全部项）。
    func registerItems(_ items: [SidebarItem])

    /// 追加侧边栏项（保留已有项）。
    ///
    /// 供多个插件各自贡献入口时使用，互不覆盖。
    func addItems(_ items: [SidebarItem])

    /// 按 id 撤回插件贡献的入口项。
    func removeItems(ids: Set<String>)

    /// 激活指定入口。未知 id 忽略；传 nil 表示清除激活。
    func activateItem(id: String?)

    /// 返回侧边栏视图（基于已注入的 items 渲染）。
    func makeSidebarView() -> AnyView

}

public extension SidebarProviding {
    var activeItemID: String? { nil }

    /// 追加语义的默认实现：合入已有项并按 `order` 排序（同 id 去重，保留先注册者）。
    func addItems(_ newItems: [SidebarItem]) {
        var merged = items
        for item in newItems where !merged.contains(where: { $0.id == item.id }) {
            merged.append(item)
        }
        registerItems(merged)
    }

    func removeItems(ids: Set<String>) {
        registerItems(items.filter { !ids.contains($0.id) })
    }

    func activateItem(id: String?) {}
}
