import LibGit2Swift
import MagicKit
import SwiftUI

/// 提交信息显示视图组件
/// 包含提交消息、作者信息、时间和 Hash 等详细信息
struct CommitInfoView: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📋"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 提交对象
    let commit: GitCommit

    /// 是否已复制到剪贴板
    @State private var isCopied: Bool = false


    /// 是否显示提交时间详情弹窗
    @State private var showingTimePopup = false

    /// 是否显示提交Hash详情弹窗
    @State private var showingHashPopup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            /// 提交消息头部显示
            HStack {
                /// Commit 图标
                Image.dotCircle
                    .foregroundColor(.blue)
                    .font(.system(size: 12))

                /// Commit 消息
                Text(commit.message)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            Divider()

            /// Commit body（如果有）
            CommitBodyInfo(commit: commit)

            /// 提交详细信息区域
            HStack(spacing: 16) {
                /// 作者信息
                UserInfo(commit: commit)

                /// 提交时间
                CommitTimeInfo(commit: commit, showingTimePopup: $showingTimePopup)

                /// Hash 信息
                CommitHashInfo(commit: commit, isCopied: $isCopied, showingHashPopup: $showingHashPopup)

                Spacer()
            }
            .background(.red.opacity(0))
        }
        .onApplicationDidBecomeActive(perform: handleOnAppear)
    }
}

// MARK: - View

extension CommitInfoView {

}

// MARK: - Event Handler

extension CommitInfoView {
    /// 视图出现时的事件处理
    func handleOnAppear() {
        // 用户信息现在由 UserInfo 组件内部处理
    }
}

// MARK: - Private Helpers

extension CommitInfoView {
    // 用户信息解析现在由 UserInfo 组件内部处理
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

// MARK: - Preview

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
