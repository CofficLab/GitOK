import GitOKFoundationKit
import SwiftUI

public extension View {
    /// 将视图包装在 MacDesktop 中
    /// 创建一个模拟 macOS 桌面的布局，包含顶部任务栏和底部 Dock
    func inDesktop() -> some View {
        MacDesktop {
            self
        }
    }
}

// MARK: - Preview

