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

    /// 头像用户列表
    @State private var avatarUsers: [AvatarUser] = []

    /// 是否显示提交时间详情弹窗
    @State private var showingTimePopup = false

    /// 是否显示提交Hash详情弹窗
    @State private var showingHashPopup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Commit 图标
                Image.dotCircle
                    .foregroundColor(.blue)
                    .font(.system(size: 12))

                // Commit 消息
                Text(commit.message)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

            Divider()

            // Commit body（如果有）
            CommitBodyInfo(commit: commit)

            HStack(spacing: 16) {
                // 作者信息（可点击的头像+用户名）
                if !commit.author.isEmpty {
                    if !avatarUsers.isEmpty {
                        UserInfo(users: avatarUsers, avatarSize: 18, maxVisibleCount: 3)
                    } else {
                        // 回退图标
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.allAuthors)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // 提交时间
                CommitTimeInfo(commit: commit, showingTimePopup: $showingTimePopup)

                // Hash 信息
                CommitHashInfo(commit: commit, isCopied: $isCopied, showingHashPopup: $showingHashPopup)

                Spacer()
            }
        }
        .onAppear {
            loadAvatarUsers()
        }
    }

    // MARK: - 头像加载

    /// 解析提交的作者信息（包括 co-authors）
    private func loadAvatarUsers() {
        var users: [AvatarUser] = []

        // 解析作者信息
        let authorName: String
        let authorEmail: String

        // author 格式可能是 "name <email>" 或只是 "name"
        if let emailRange = commit.author.range(of: "<([^>]+)>", options: .regularExpression) {
            // 有邮箱
            let emailStartIndex = commit.author.index(emailRange.lowerBound, offsetBy: 1)
            let emailEndIndex = commit.author.index(emailRange.upperBound, offsetBy: -1)
            authorEmail = String(commit.author[emailStartIndex ..< emailEndIndex])

            let nameEndIndex = commit.author.index(emailRange.lowerBound, offsetBy: -2)
            authorName = String(commit.author[..<nameEndIndex]).trimmingCharacters(in: .whitespaces)
        } else {
            // 没有邮箱，使用 author 作为 name
            authorName = commit.author
            authorEmail = ""
        }

        // 添加主作者
        let author = AvatarUser(
            name: authorName,
            email: authorEmail
        )
        users.append(author)

        // 解析 co-authors
        let coAuthors = parseCoAuthors(from: commit.message)
        users.append(contentsOf: coAuthors)

        // 去重（基于邮箱）
        var seenEmails = Set<String>()
        var uniqueUsers: [AvatarUser] = []

        for user in users {
            if !seenEmails.contains(user.email) {
                seenEmails.insert(user.email)
                uniqueUsers.append(user)
            }
        }

        self.avatarUsers = uniqueUsers
    }

    /// 从 commit 消息中解析 co-authors
    /// - Parameter message: commit 消息
    /// - Returns: co-author 列表
    private func parseCoAuthors(from message: String) -> [AvatarUser] {
        var coAuthors: [AvatarUser] = []

        // Co-authored-by 格式：Co-authored-by: name <email>
        let pattern = #"Co-authored-by:\s*([^<]+?)\s*<([^>]+)>"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(message.startIndex..., in: message)
            let matches = regex.matches(in: message, range: range)

            for match in matches {
                if match.numberOfRanges >= 3 {
                    let nameRange = Range(match.range(at: 1), in: message)!
                    let emailRange = Range(match.range(at: 2), in: message)!

                    let name = String(message[nameRange]).trimmingCharacters(in: .whitespaces)
                    let email = String(message[emailRange]).trimmingCharacters(in: .whitespaces)

                    coAuthors.append(AvatarUser(name: name, email: email))
                }
            }
        }

        return coAuthors
    }
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
