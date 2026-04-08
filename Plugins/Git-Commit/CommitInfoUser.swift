import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 可点击的用户信息组件
/// 点击时显示用户详细信息弹窗
struct CommitInfoUser: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👆"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 提交对象，用于解析用户信息
    let commit: GitCommit

    /// 解析出的用户信息（基于当前commit计算）
    private var avatarUser: AvatarUser? {
        parseAuthorInfo()
    }

    /// 是否显示用户信息弹窗
    @State private var showingPopup = false

    /// 初始化可点击用户信息组件
    /// - Parameter commit: 提交对象，用于解析用户信息
    init(commit: GitCommit) {
        self.commit = commit
    }

    var body: some View {
        /// 如果作者信息为空，不显示任何内容
        if commit.author.isEmpty {
            EmptyView()
        } else {
            AppIconButton(
                systemImage: "person.circle",
                label: avatarUser?.name ?? String(localized: "Unknown", table: "GitCommit"),
                tint: DesignTokens.Color.semantic.textSecondary,
                size: .regular
            ) {
                showingPopup = true
            }
            .help(String(localized: "点击查看用户信息", table: "GitCommit"))
            .popover(isPresented: $showingPopup, arrowEdge: .bottom) {
                /// 直接使用 avatarUser
                if let user = avatarUser {
                    CommitInfoUserInfoPopup(user: user)
                        .frame(width: 600)
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    /// 只有在真的没有用户时才显示这个
                    Text("未找到用户信息", tableName: "GitCommit")
                        .frame(width: 200, height: 100)
                }
            }
        }
    }
}

// MARK: - Private Helpers

extension CommitInfoUser {
    /// 解析提交的作者信息
    private func parseAuthorInfo() -> AvatarUser? {
        if Self.verbose {
            os_log("\(self.t)开始解析作者信息: \(commit.author)")
        }

        /// author 格式可能是 "name <email>" 或只是 "name"
        if let emailRange = commit.author.range(of: "<([^>]+)>", options: .regularExpression) {
            /// 有邮箱
            let emailStartIndex = commit.author.index(emailRange.lowerBound, offsetBy: 1)
            let emailEndIndex = commit.author.index(emailRange.upperBound, offsetBy: -1)
            let authorEmail = String(commit.author[emailStartIndex ..< emailEndIndex])

            let nameEndIndex = commit.author.index(emailRange.lowerBound, offsetBy: -2)
            let authorName = String(commit.author[..<nameEndIndex]).trimmingCharacters(in: .whitespaces)

            let user = AvatarUser(name: authorName, email: authorEmail)
            if Self.verbose {
                os_log("\(self.t)✅ 成功解析带邮箱的作者: \(authorName) <\(authorEmail)>")
            }
            return user
        } else {
            /// 没有邮箱，使用 author 作为 name
            let user = AvatarUser(name: commit.author, email: "")
            return user
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    HStack(spacing: 20) {
        CommitInfoUser(
            commit: GitCommit(
                id: "1",
                hash: "abc123",
                author: "octocat <octocat@users.noreply.github.com>",
                email: "",
                date: Date(),
                message: "Test commit",
                body: "",
                refs: [],
                tags: []
            )
        )

        CommitInfoUser(
            commit: GitCommit(
                id: "2",
                hash: "def456",
                author: "Alice",
                email: "",
                date: Date(),
                message: "Test commit 2",
                body: "",
                refs: [],
                tags: []
            )
        )

        CommitInfoUser(
            commit: GitCommit(
                id: "3",
                hash: "ghi789",
                author: "", // 空作者测试
                email: "",
                date: Date(),
                message: "Test commit 3",
                body: "",
                refs: [],
                tags: []
            )
        )
    }
    .padding()
}

#Preview("Content Layout - Small") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
