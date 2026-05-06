import SwiftUI
import MagicKit

/// Commit 消息输入框组件
/// 提供提交消息的文本输入功能，支持占位符显示
struct CommitMessageInput: View {
    /// 绑定到外部的文本内容
    @Binding var text: String

    /// 输入框占位符文本
    var placeholder: String = "commit"

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .padding(.vertical)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
