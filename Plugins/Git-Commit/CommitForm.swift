import MagicKit
import OSLog
import SwiftUI

struct CommitForm: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider

    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var commitStyle: CommitStyle = .emoji

    var commitMessage: String {
        var c = text
        if c.isEmpty {
            c = "Auto Committed by GitOK"
        }

        return "\(category.text(style: commitStyle)) \(c)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    CommitStylePicker(
                        selection: $commitStyle
                    )

                    CommitCategoryPicker(
                        selection: $category,
                        commitStyle: commitStyle
                    )
                }

                Spacer()
                CommitMessageInput(text: $text)
            }

            HStack {
                UserView().frame(maxWidth: 300)

                Spacer()

                BtnCommitAndPush(commitMessage: commitMessage, commitOnly: true)
                BtnCommitAndPush(commitMessage: commitMessage)
            }
            .frame(height: 40)
        }
        .onProjectDidCommit(perform: onProjectDidCommit)
        .onChange(of: category, onCategoryDidChange)
        .onChange(of: commitStyle) { _, _ in
            onCommitStyleDidChange()
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension CommitForm {
    /// 根据类别和风格生成默认消息
    private func defaultMessage(for category: CommitCategory, style: CommitStyle) -> String {
        let baseMessage = category.defaultMessage

        // 如果是小写风格，将首字母转换为小写
        if style.isLowercase {
            return lowercasedFirst(baseMessage)
        }

        return baseMessage
    }

    /// 将字符串的首字母转换为小写
    private func lowercasedFirst(_ string: String) -> String {
        guard let first = string.first else {
            return string
        }

        return first.lowercased() + string.dropFirst()
    }
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        self.text = defaultMessage(for: category, style: commitStyle)
    }

    func onCategoryDidChange() {
        self.text = defaultMessage(for: category, style: commitStyle)
    }

    func onCommitStyleDidChange() {
        // 如果当前文本是该类别的默认消息（任何风格），则更新为新风格的默认消息
        let isDefaultMessage = CommitStyle.allCases.contains { style in
            text == defaultMessage(for: category, style: style)
        }

        if isDefaultMessage || text.isEmpty {
            self.text = defaultMessage(for: category, style: commitStyle)
        }
    }

    func onAppear() {
        self.text = defaultMessage(for: category, style: commitStyle)
        // 从当前项目读取 commitStyle，如果没有项目则使用默认值
        self.commitStyle = g.project?.commitStyle ?? .emoji
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
