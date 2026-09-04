import SwiftUI

/// 调试辅助：在视图指定角（默认右上角）叠加一个显示区块名称的 badge。
///
/// 仅用于 Debug 构建下肉眼识别根布局各区块的边界与归属
/// （RootViewProviding 渲染的工具栏 / 侧边栏 / Rail / Header /
/// 内容区 / Footer / 状态栏 / 右侧面板）。Release 构建下
/// `debugBlockBadge(_:)` 为空操作，不影响线上行为。
#if DEBUG
extension View {
    /// 在 DEBUG 构建下，于视图指定角叠加显示 `name` 的调试 badge。
    ///
    /// 默认叠加在右上角（`alignment: .topTrailing`）；需要显示在右下角等
    /// 其他位置时传入对应 alignment。通过 `.overlay(alignment:)` 实现，
    /// 不改变原视图布局；badge 本身 `allowsHitTesting(false)`，不拦截任何交互，
    /// 且对辅助功能隐藏。
    @ViewBuilder
    func debugBlockBadge(
        _ name: String,
        alignment: Alignment = .topTrailing
    ) -> some View {
        overlay(alignment: alignment) {
            Text(name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange.opacity(0.88)))
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .padding(4)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
#else
extension View {
    /// Release 构建下为空操作。
    @ViewBuilder
    func debugBlockBadge(
        _ name: String,
        alignment: Alignment = .topTrailing
    ) -> some View {
        self
    }
}
#endif
