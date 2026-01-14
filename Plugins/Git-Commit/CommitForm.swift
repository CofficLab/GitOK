import MagicKit
import OSLog
import SwiftUI

/// 提交表单视图组件
/// 提供提交消息输入、分类选择和风格选择功能，支持一键提交和推送操作
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

    /// 提交分类
    @State var category: CommitCategory = .Chore

    /// 提交消息风格
    @State var commitStyle: CommitStyle = .emoji

    /// 生成的完整提交消息
    /// 根据选择的分类和风格自动生成提交消息格式
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
}

// MARK: - Setter

extension CommitForm {
    /// 更新提交消息文本
    @MainActor
    private func setText(_ newValue: String) {
        text = newValue
    }

    /// 更新提交分类
    @MainActor
    private func setCategory(_ newValue: CommitCategory) {
        category = newValue
    }

    /// 更新提交风格
    @MainActor
    private func setCommitStyle(_ newValue: CommitStyle) {
        commitStyle = newValue
    }
}

// MARK: - Event Handler

extension CommitForm {
    /// 项目提交成功后的事件处理
    /// 重置提交消息为当前类别和风格的默认消息
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        setText(defaultMessage(for: category, style: commitStyle))
    }

    /// 提交分类变更后的事件处理
    /// 更新提交消息为新分类的默认消息
    func onCategoryDidChange() {
        setText(defaultMessage(for: category, style: commitStyle))
    }

    /// 提交风格变更后的事件处理
    /// 如果当前文本是默认消息，则更新为新风格的默认消息
    func onCommitStyleDidChange() {
        // 如果当前文本是该类别的默认消息（任何风格），则更新为新风格的默认消息
        let isDefaultMessage = CommitStyle.allCases.contains { style in
            text == defaultMessage(for: category, style: style)
        }

        if isDefaultMessage || text.isEmpty {
            setText(defaultMessage(for: category, style: commitStyle))
        }
    }

    /// 视图出现时的事件处理
    /// 初始化提交消息并从项目配置中读取提交风格
    func onAppear() {
        setText(defaultMessage(for: category, style: commitStyle))
        // 从当前项目读取 commitStyle，如果没有项目则使用默认值
        setCommitStyle(g.project?.commitStyle ?? .emoji)
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
