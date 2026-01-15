import SwiftUI
import MagicUI

// 确保能访问 AvatarUser、AvatarView、AvatarStackView
// 这些类型已在其他文件中定义

/// 用户信息弹出视图组件
/// 显示用户的详细信息，包括头像、名称、邮箱等
struct UserInfoPopup: View {
    let user: AvatarUser

    @State private var avatarURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部：头像和名称
            HStack(alignment: .center, spacing: 12) {
                // 大头像
                AvatarView(user: user, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    // 用户名
                    Text(user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // GitHub 用户标识
                    if !user.email.isEmpty, !gitHubUsername.isEmpty {
                        Text(gitHubUsername)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(16)

            Divider()

            // 信息列表（使用 MagicSettingRow）
            VStack(spacing: 0) {
                // 用户名
                infoRow(
                    title: "用户名",
                    value: user.name,
                    icon: .iconUser
                )

                if !user.email.isEmpty {
                    Divider()

                    // 邮箱
                    infoRow(
                        title: "邮箱",
                        value: user.email,
                        icon: .iconMail,
                        selectable: true
                    )

                    Divider()

                    // GitHub 用户名（如果有）
                    if !gitHubUsername.isEmpty {
                        infoRow(
                            title: "GitHub",
                            value: gitHubUsername,
                            icon: .iconInfo
                        )

                        Divider()
                    }

                    // 头像 URL（如果有）
                    if let url = avatarURL {
                        infoRow(
                            title: "头像地址",
                            value: url.absoluteString,
                            icon: .iconSafari,
                            selectable: true
                        )

                        Divider()
                    }

                    // GitHub 主页按钮
                    if let githubURL = gitHubURL {
                        linkRow(
                            title: "GitHub 主页",
                            url: githubURL.absoluteString,
                            icon: .iconSafari
                        )
                    }
                }
            }
        }
        .frame(width: 360)
        .onAppear {
            loadAvatarURL()
        }
    }

    /// 异步加载头像 URL
    private func loadAvatarURL() {
        Task {
            if let url = await AvatarService.shared.getAvatarURL(name: user.name, email: user.email) {
                await MainActor.run {
                    self.avatarURL = url
                }
            }
        }
    }

    // MARK: - View Components

    /// 信息行（类似 AboutView 的样式）
    private func infoRow(title: String, value: String, icon: String, selectable: Bool = false) -> some View {
        MagicSettingRow(
            title: title,
            description: value,
            icon: icon
        ) {
            if selectable {
                // 可选择的文本，可以复制
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            } else {
                EmptyView()
            }
        }
    }

    /// 链接行（可点击打开）
    private func linkRow(title: String, url: String, icon: String) -> some View {
        MagicSettingRow(
            title: title,
            description: url,
            icon: icon
        ) {
            MagicButton.simple {
                if let url = URL(string: url) {
                    NSWorkspace.shared.open(url)
                }
            }
            .magicIcon(.iconSafari)
            .magicShape(.circle)
            .magicShapeVisibility(.onHover)
        }
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
