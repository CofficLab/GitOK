import MagicKit
import OSLog
import SwiftUI

/// Git 提交表单视图：提供提交消息的编辑界面，支持类别选择和风格配置。
struct CommitForm: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📝"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 环境对象：应用提供者
    @EnvironmentObject var app: AppProvider

    /// 环境对象：数据提供者
    @EnvironmentObject var g: DataProvider

    /// 提交消息文本
    @State var text: String = ""

    /// 提交类别
    @State var category: CommitCategory = .Chore

    /// 提交风格
    @State var commitStyle: CommitStyle = .emoji

    /// 生成的提交消息
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
    /// - Parameters:
    ///   - category: 提交类别
    ///   - style: 提交风格
    /// - Returns: 生成的默认消息
    private func defaultMessage(for category: CommitCategory, style: CommitStyle) -> String {
        let baseMessage = category.defaultMessage

        // 如果是小写风格，将首字母转换为小写
        if style.isLowercase {
            return lowercasedFirst(baseMessage)
        }

        return baseMessage
    }

    /// 将字符串的首字母转换为小写
    /// - Parameter string: 输入字符串
    /// - Returns: 首字母小写的字符串
    private func lowercasedFirst(_ string: String) -> String {
        guard let first = string.first else {
            return string
        }

        return first.lowercased() + string.dropFirst()
    }
}

// MARK: - Event Handler

extension CommitForm {
    /// 项目提交成功时的事件处理
    /// - Parameter eventInfo: 项目事件信息
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        self.text = defaultMessage(for: category, style: commitStyle)
    }

    /// 提交类别变更时的事件处理
    func onCategoryDidChange() {
        self.text = defaultMessage(for: category, style: commitStyle)
    }

    /// 提交风格变更时的事件处理
    func onCommitStyleDidChange() {
        updateText(for: category, style: commitStyle)
    }

    /// 视图出现时的事件处理
    func onAppear() {
        self.text = defaultMessage(for: category, style: commitStyle)
        // 从当前项目读取 commitStyle，如果没有项目则使用默认值
        self.commitStyle = g.project?.commitStyle ?? .emoji
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
