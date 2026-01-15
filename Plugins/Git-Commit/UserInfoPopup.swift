import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 用户信息弹出视图组件
/// 显示用户的详细信息，包括头像、名称、邮箱等
struct UserInfoPopup: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 要显示的用户信息
    let user: AvatarUser

    /// 从API获取的头像URL
    @State private var avatarURL: URL?

    /// 当前显示的头像 URL（优先使用从 API 获取的，否则使用 Gravatar）
    private var displayedAvatarURL: URL {
        if let url = avatarURL {
            return url
        }
        // 使用 Gravatar URL 作为默认值
        return AvatarService.shared.getGravatarURL(email: user.email, size: 64)
    }

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

                Divider()

                // 头像地址（总是显示）
                infoRow(
                    title: "头像地址",
                    value: displayedAvatarURL.absoluteString,
                    icon: .iconSafari,
                    selectable: true
                )

                // 邮箱（如果有）
                if !user.email.isEmpty {
                    Divider()

                    infoRow(
                        title: "邮箱",
                        value: user.email,
                        icon: .iconMail,
                        selectable: true
                    )
                }

                // GitHub 主页按钮（如果有）
                if let githubURL = gitHubURL {
                    Divider()

                    linkRow(
                        title: "GitHub 主页",
                        url: githubURL.absoluteString,
                        icon: .iconSafari
                    )
                }
            }
        }
        .frame(width: 600)
        .onAppear {
            loadAvatarURL()
        }
    }

    /// 异步加载头像 URL
    /// 从 AvatarService 获取用户的头像 URL
    private func loadAvatarURL() {
        Task {
            if let url = await AvatarService.shared.getAvatarURL(name: user.name, email: user.email) {
                await MainActor.run {
                    self.avatarURL = url
                }
            }
        }
    }
}

// MARK: - View

extension UserInfoPopup {
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
    /// 如果是 GitHub 的自动生成邮箱，则返回 @用户名 格式
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

// MARK: - ClickableUserInfo

/// 可点击的用户信息组件
/// 点击时显示用户详细信息弹窗
struct ClickableUserInfo: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👆"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 要显示的用户列表
    let users: [AvatarUser]

    /// 头像尺寸
    let avatarSize: CGFloat

    /// 最大显示的用户数量
    let maxVisibleCount: Int

    /// 是否显示用户信息弹窗
    @State private var showingPopup = false

    /// 初始化可点击用户信息组件
    /// - Parameters:
    ///   - users: 要显示的用户列表
    ///   - avatarSize: 头像尺寸，默认18
    ///   - maxVisibleCount: 最大显示的用户数量，默认3
    init(users: [AvatarUser], avatarSize: CGFloat = 18, maxVisibleCount: Int = 3) {
        self.users = users
        self.avatarSize = avatarSize
        self.maxVisibleCount = maxVisibleCount
    }

    var body: some View {
        Button(action: {
            showingPopup = true
            if Self.verbose {
                if let firstUser = users.first {
                    os_log("\(self.t)点击了用户: \(firstUser.name), 邮箱: \(firstUser.email)")
                } else {
                    os_log("\(self.t)用户列表为空")
                }
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

    /// 所有作者姓名的文本表示（用逗号分隔）
    private var allAuthorsText: String {
        users.map { $0.name }.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
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
    .frame(width: 800)
}

#Preview("App - Big Screen") {
    HStack(spacing: 20) {
        ClickableUserInfo(
            users: [
                AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"),
            ],
            avatarSize: 18
        )

        ClickableUserInfo(
            users: [
                AvatarUser(name: "Alice", email: "alice@example.com"),
                AvatarUser(name: "Bob", email: "bob@example.com"),
            ],
            avatarSize: 18
        )
    }
    .padding()
}

#Preview("App - Small Screen") {
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
