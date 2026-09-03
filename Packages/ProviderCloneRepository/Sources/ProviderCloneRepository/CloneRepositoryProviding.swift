import SwiftUI

/// 克隆仓库提供能力协议
///
/// 定义「克隆仓库入口按钮 → 克隆仓库 sheet」这一段的最小契约：
/// PluginCloneRepository 实现本协议（持有项目管理、活动上报、toast 等依赖），
/// 提供可展示的克隆仓库 sheet 视图；PluginSidebar 等入口在侧边栏底部
/// 以 sheet 形式展示 `makeCloneSheetView()` 的返回值。
///
/// 协议只声明能力，不关心具体克隆逻辑（由实现方通过 KitGit 完成）。
@MainActor
public protocol CloneRepositoryProviding: AnyObject {
    /// 返回克隆仓库 sheet 的视图（入口按钮以 `.sheet` 展示）。
    func makeCloneSheetView() -> AnyView
}
