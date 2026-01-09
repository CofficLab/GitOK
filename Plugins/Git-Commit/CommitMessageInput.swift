import SwiftUI
import MagicKit

/// Commit 消息输入框
struct CommitMessageInput: View {
    @Binding var text: String
    var placeholder: String = "commit"

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .padding(.vertical)
    }
}

// MARK: - Preview

#Preview("App-Small Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .hideSidebar()
        .inRootView()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
