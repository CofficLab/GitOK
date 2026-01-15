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
                Image(systemName: "smallcircle.filled.circle")
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
            if !commit.body.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text(commit.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(10)
                        .textSelection(.enabled)

                    Spacer()
                }
            }

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
                if commit.date != Date(timeIntervalSince1970: 0) {
                    Button(action: {
                        showingTimePopup = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.date.fullDateTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("点击查看完整时间信息")
                    .popover(isPresented: $showingTimePopup, arrowEdge: .bottom) {
                        CommitTimePopup(commit: commit)
                            .frame(width: 350)
                            .background(Color(nsColor: .windowBackgroundColor))
                    }
                }

                // Hash 信息
                if !commit.hash.isEmpty {
                    Button(action: {
                        showingHashPopup = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.hash.prefix(8))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)

                            // 复制按钮
                            Button(action: {
                                commit.hash.copy()
                                withAnimation(.spring()) {
                                    isCopied = true
                                }

                                // 1.5秒后重置状态
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation(.spring()) {
                                        isCopied = false
                                    }
                                }
                            }) {
                                Image(systemName: isCopied ? "checkmark.circle" : "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundColor(isCopied ? .green : .secondary)
                                    .scaleEffect(isCopied ? 1.2 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .help(isCopied ? "已复制" : "复制完整 Hash")

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .help("点击查看完整 Hash 信息")
                    .popover(isPresented: $showingHashPopup, arrowEdge: .bottom) {
                        CommitHashPopup(commit: commit, isCopied: $isCopied)
                            .frame(width: 450)
                            .background(Color(nsColor: .windowBackgroundColor))
                    }
                }

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

// MARK: - CommitTimePopup

/// 提交时间详情弹出组件
struct CommitTimePopup: View {
    let commit: GitCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("提交时间详情")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // 时间信息列表
            VStack(spacing: 12) {
                // 完整日期时间
                timeInfoRow(
                    title: "完整时间",
                    value: commit.date.fullDateTime,
                    icon: "clock.fill"
                )

                // 相对时间
                timeInfoRow(
                    title: "相对时间",
                    value: commit.date.formatted(.relative(presentation: .named)),
                    icon: "clock.arrow.circlepath"
                )

                // ISO 格式
                timeInfoRow(
                    title: "ISO 格式",
                    value: ISO8601DateFormatter().string(from: commit.date),
                    icon: "calendar.badge.clock",
                    selectable: true
                )

                // Unix 时间戳
                timeInfoRow(
                    title: "Unix 时间戳",
                    value: "\(Int(commit.date.timeIntervalSince1970))",
                    icon: "number.circle",
                    selectable: true
                )
            }
        }
        .padding(20)
    }

    private func timeInfoRow(title: String, value: String, icon: String, selectable: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectable {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                } else {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - CommitHashPopup

/// 提交Hash详情弹出组件
struct CommitHashPopup: View {
    let commit: GitCommit
    @Binding var isCopied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("提交 Hash 详情")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // Hash 信息列表
            VStack(spacing: 12) {
                // 完整 Hash
                hashInfoRow(
                    title: "完整 Hash",
                    value: commit.hash,
                    icon: "number.circle.fill",
                    selectable: true,
                    showCopyButton: true
                )

                // 短 Hash (8位)
                hashInfoRow(
                    title: "短 Hash (8位)",
                    value: String(commit.hash.prefix(8)),
                    icon: "number.circle",
                    selectable: true,
                    showCopyButton: true
                )

                // Hash 长度
                hashInfoRow(
                    title: "Hash 长度",
                    value: "\(commit.hash.count) 字符",
                    icon: "ruler",
                    selectable: false,
                    showCopyButton: false
                )

                // Hash 前缀检查
                if commit.hash.hasPrefix("0") {
                    hashInfoRow(
                        title: "前缀特征",
                        value: "以 0 开头",
                        icon: "exclamationmark.triangle",
                        selectable: false,
                        showCopyButton: false
                    )
                }
            }
        }
        .padding(20)
    }

    private func hashInfoRow(title: String, value: String, icon: String, selectable: Bool, showCopyButton: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectable {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                } else {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            if showCopyButton {
                Button(action: {
                    value.copy()
                    withAnimation(.spring()) {
                        isCopied = true
                    }

                    // 1.5秒后重置状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring()) {
                            isCopied = false
                        }
                    }
                }) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isCopied ? .green : .secondary)
                        .scaleEffect(isCopied ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
                .help(isCopied ? "已复制" : "复制到剪贴板")
            }
        }
        .padding(.vertical, 8)
    }
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
