import SwiftUI

// 确保能访问 AvatarUser、AvatarView、AvatarStackView
// 这些类型已在其他文件中定义

/// 用户信息弹出视图组件
/// 显示用户的详细信息，包括头像、名称、邮箱等
struct UserInfoPopup: View {
    let user: AvatarUser

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部：头像和名称
            HStack(spacing: 12) {
                // 大头像
                AvatarView(user: user, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    // 用户名
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // GitHub 用户标识
                    if !user.email.isEmpty {
                        Text(gitHubUsername)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            // 邮箱信息
            if !user.email.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("邮箱")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(user.email)
                        .font(.body)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }

                Divider()
            }

            // GitHub 链接
            if !user.email.isEmpty, let url = gitHubURL {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GitHub")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .font(.caption)
                            Text(url.absoluteString)
                                .font(.body)
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    /// 从邮箱中提取 GitHub 用户名
    private var gitHubUsername: String {
        // GitHub 邮箱格式：username@users.noreply.github.com
        let pattern = #"^(.+)@users\.noreply\.github\.com$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: user.email, range: NSRange(user.email.startIndex..., in: user.email)) {
            if let usernameRange = Range(match.range(at: 1), in: user.email) {
                return "@\(String(user.email[usernameRange]))"
            }
        }

        // 如果不是 GitHub 邮箱，返回空
        return ""
    }

    /// 生成 GitHub 个人主页 URL
    private var gitHubURL: URL? {
        // 从邮箱中提取用户名
        let pattern = #"^(.+)@users\.noreply\.github\.com$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: user.email, range: NSRange(user.email.startIndex..., in: user.email)) {
            if let usernameRange = Range(match.range(at: 1), in: user.email) {
                let username = String(user.email[usernameRange])
                return URL(string: "https://github.com/\(username)")
            }
        }

        // 如果邮箱不是 GitHub 格式，尝试使用名称作为用户名
        if !user.name.isEmpty {
            return URL(string: "https://github.com/\(user.name)")
        }

        return nil
    }
}

/// 可点击的用户信息组件
struct ClickableUserInfo: View {
    let users: [AvatarUser]
    let avatarSize: CGFloat
    let maxVisibleCount: Int

    @State private var showingPopup = false

    init(users: [AvatarUser], avatarSize: CGFloat = 18, maxVisibleCount: Int = 3) {
        self.users = users
        self.avatarSize = avatarSize
        self.maxVisibleCount = maxVisibleCount
    }

    var body: some View {
        Button(action: {
            showingPopup = true
            if let firstUser = users.first {
                print("点击了用户: \(firstUser.name), 邮箱: \(firstUser.email)")
            } else {
                print("用户列表为空")
            }
        }) {
            HStack(spacing: 6) {
                // 头像堆栈
                if !users.isEmpty {
                    AvatarStackView(users: users, avatarSize: avatarSize, maxVisibleCount: maxVisibleCount)

                    // 用户名
                    Text(allAuthorsText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .help("点击查看用户信息")
        .popover(isPresented: $showingPopup, arrowEdge: .bottom) {
            // 直接使用 users.first，不依赖状态
            if let user = users.first {
                UserInfoPopup(user: user)
                    .frame(width: 300)
                    .background(Color(nsColor: .windowBackgroundColor))
            } else {
                // 只有在真的没有用户时才显示这个
                Text("未找到用户信息")
                    .frame(width: 200, height: 100)
            }
        }
    }

    private var allAuthorsText: String {
        users.map { $0.name }.joined(separator: ", ")
    }
}

#Preview("User Info Popup") {
    VStack(spacing: 20) {
        // GitHub 用户
        UserInfoPopup(user: AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"))

        Divider()

        // 普通用户
        UserInfoPopup(user: AvatarUser(name: "John Doe", email: "john@example.com"))

        Divider()

        // 无邮箱用户
        UserInfoPopup(user: AvatarUser(name: "Anonymous", email: ""))
    }
    .padding()
    .frame(width: 400)
}

#Preview("Clickable User Info") {
    HStack(spacing: 20) {
        ClickableUserInfo(
            users: [
                AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com")
            ],
            avatarSize: 18
        )

        ClickableUserInfo(
            users: [
                AvatarUser(name: "Alice", email: "alice@example.com"),
                AvatarUser(name: "Bob", email: "bob@example.com")
            ],
            avatarSize: 18
        )
    }
    .padding()
}
