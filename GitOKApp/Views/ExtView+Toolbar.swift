import GitOKSupportKit
import SwiftUI

/// 工具栏按钮样式修饰符
struct ToolbarButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(height: 36)
            .frame(width: 36)
            .hoverBackground(Color.accentColor.opacity(0.2))
            .roundedFull()
    }
}
