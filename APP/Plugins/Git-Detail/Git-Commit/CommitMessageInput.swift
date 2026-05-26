import SwiftUI
import MagicKit
import ProjectRulesKit

/// Commit 消息输入框组件
/// 提供提交消息的文本输入功能，支持占位符显示
struct CommitMessageInput: View {
    /// 绑定到外部的文本内容
    @Binding var text: String

    /// 输入框占位符文本
    var placeholder: String = "commit"

    var issueReferences: [String] = []
    var userMentions: [String] = []

    private var completions: [CommitAutocompleteRules.Completion] {
        CommitAutocompleteRules.completions(
            for: text,
            issueReferences: issueReferences,
            userMentions: userMentions
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)

            if completions.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(completions) { completion in
                            Button {
                                text = CommitAutocompleteRules.text(text, applying: completion)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: systemImage(for: completion.kind))
                                        .font(.caption2)
                                    Text(completion.title)
                                        .font(.caption2.monospaced())
                                    Text(completion.detail)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.borderless)
                            .help("插入 \(completion.title)")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.vertical)
    }

    private func systemImage(for kind: CommitAutocompleteRules.CompletionKind) -> String {
        switch kind {
        case .issue:
            return "number"
        case .user:
            return "person.crop.circle"
        case .emoji:
            return "face.smiling"
        }
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
