import GitOKFoundationKit
import SwiftUI

extension View {
    /// 将视图居中显示在容器中
    /// 使用 ZStack 和 Spacer 实现水平和垂直居中布局
    public func magicCentered() -> some View {
        ZStack {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    self
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview

