import SwiftUI

/// 调试辅助：在视图左上角叠加一个显示插件名称的 badge。
///
/// 仅用于 Debug 构建下肉眼识别当前主内容区由哪个插件渲染。
/// Release 构建下 `debugPluginBadge(_:)` 为空操作，不影响线上行为。
#if DEBUG
extension View {
    /// 在 DEBUG 构建下，于视图右下角叠加显示 `name` 的调试 badge。
    ///
    /// 通过 `.overlay(alignment: .bottomTrailing)` 实现，不改变原视图布局；
    /// badge 本身 `allowsHitTesting(false)`，不拦截任何交互，且对辅助功能隐藏。
    @ViewBuilder
    func debugPluginBadge(_ name: String) -> some View {
        overlay(alignment: .bottomTrailing) {
            Text(name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.purple.opacity(0.85)))
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
    func debugPluginBadge(_ name: String) -> some View {
        self
    }
}
#endif
