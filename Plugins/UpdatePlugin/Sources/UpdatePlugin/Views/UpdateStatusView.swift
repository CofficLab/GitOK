import Sparkle
import SwiftUI

/// 更新状态视图（状态栏指示器）
///
/// 简化版：Sparkle 自带更新检查和通知 UI，状态栏不再需要自定义状态管理。
/// 当 Sparkle 检测到更新时会自动弹窗，无需手动触发。
public struct UpdateStatusView: View {
    public init() {}

    public var body: some View {
        // Sparkle 自带更新通知 UI，状态栏不需要额外指示器
        EmptyView()
    }
}
