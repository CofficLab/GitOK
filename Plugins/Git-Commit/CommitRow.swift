
import LibGit2Swift
import MagicKit
import SwiftUI

/// 提交记录行视图组件
/// 显示单个 Git 提交的详细信息，包括消息、作者、时间等
struct CommitRow: View, SuperThread {
    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 提交对象
    let commit: GitCommit

    /// 是否未同步到远程
    let isUnpushed: Bool

    /// 标签文本
    @State private var tag: String = ""

    /// 头像用户列表
    @State private var avatarUsers: [AvatarUser] = []

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                data.setCommit(commit)
            }) {
                HStack(alignment: .center, spacing: 12) {
                    // 左侧：头像堆栈
                    if !avatarUsers.isEmpty {
                        AvatarStackView(users: avatarUsers, avatarSize: 24, maxVisibleCount: 2)
                            .frame(width: 50, height: 24)
                    }

                    // 中间：主要内容
                    VStack(alignment: .leading, spacing: 2) {
                        // 第一行：提交消息标题
                        HStack {
                            Text(commit.message)
                                .lineLimit(1)
                                .font(.system(size: 13))
                            Spacer()
                        }

                        // 第二行：所有作者（包括 Co-Authored-By）
                        HStack {
                            Text(commit.allAuthors)
                                .padding(.vertical, 1)
                                .lineLimit(1)

                            // 相对时间标签
                            Text(commit.date.smartRelativeTime)
                                .padding(.vertical, 1)
                                .padding(.horizontal, 1)

                            Spacer()
                        }
                        .padding(.vertical, 1)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                        // 第三行：提交时间（完整）
                        HStack {
                            Text(commit.date.fullDateTime)
                                .lineLimit(1)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.leading, 8)
                    .frame(minHeight: 25)

                    // 右侧：未推送到远程的图标（当需要显示时）
                    if isUnpushed {
                        Image(systemName: .iconUpload)
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 8)
                            .help("尚未推送到远程仓库")
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(data.commit == self.commit ? Color.accentColor.opacity(0.1) : Color.clear)
            .onAppear(perform: onAppear)
            .onNotification(.appWillBecomeActive, onAppWillBecomeActive)
            .onProjectDidCommit(perform: onGitCommitSuccess)

            Divider()
        }
    }

    /// 异步加载commit的tag信息
    private func loadTag() {
        guard let project = data.project else {
            self.tag = ""
            return
        }

        do {
            let tags = try project.getTags(commit: self.commit.hash)

            self.tag = tags.first ?? ""
        } catch {
            // 获取tag失败时不显示tag
        }
    }

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
            authorEmail = String(commit.author[emailStartIndex..<emailEndIndex])

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

// MARK: - Event

extension CommitRow {
    func onAppear() {
        loadAvatarUsers()
        self.bg.async {
            loadTag()
        }
    }

    func onAppWillBecomeActive(_ n: Notification) {
        loadTag()
    }

    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        loadTag()
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
