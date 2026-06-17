import GitOKCoreKit
import GitOKUI
import ProjectRulesKit
import SwiftUI

/// Commit 消息输入框组件
/// 提供提交消息的文本输入功能，支持占位符显示
public struct CommitMessageInput: View {
    /// 绑定到外部的文本内容
    @Binding var text: String

    /// 输入框占位符文本
    var placeholder: String

    var issueReferences: [String]
    var userMentions: [String]

    public init(
        text: Binding<String>,
        placeholder: String = "commit",
        issueReferences: [String] = [],
        userMentions: [String] = []
    ) {
        self._text = text
        self.placeholder = placeholder
        self.issueReferences = issueReferences
        self.userMentions = userMentions
    }

    private var completions: [CommitAutocompleteRules.Completion] {
        CommitAutocompleteRules.completions(
            for: text,
            issueReferences: issueReferences,
            userMentions: userMentions
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AppInputField(placeholder, text: $text)

            if completions.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(completions) { completion in
                            AppIconButton(
                                systemImage: systemImage(for: completion.kind),
                                label: completion.title,
                                tint: .secondary
                            ) {
                                text = CommitAutocompleteRules.text(text, applying: completion)
                            }
                            .help("插入 \(completion.title) \(completion.detail)")
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
