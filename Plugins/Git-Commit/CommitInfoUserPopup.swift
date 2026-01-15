import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 用户信息弹出视图组件
/// 显示用户的详细信息，包括头像、名称、邮箱等
struct CommitInfoUserInfoPopup: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "👤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 要显示的用户信息
    let user: AvatarUser

    /// 显示的头像 URL（从 AvatarService 获取）
    @State private var displayedAvatarURL: URL?

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
                if let avatarURL = displayedAvatarURL {
                    infoRow(
                        title: "头像地址",
                        value: avatarURL.absoluteString,
                        icon: .iconSafari,
                        selectable: true
                    )
                } else {
                    infoRow(
                        title: "头像地址",
                        value: "加载中...",
                        icon: .iconSafari,
                        selectable: false
                    )
                }

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
            let url = await AvatarService.shared.getAvatarURL(name: user.name, email: user.email, verbose: Self.verbose)
            await MainActor.run {
                self.displayedAvatarURL = url
            }
        }
    }
}

// MARK: - View

extension CommitInfoUserInfoPopup {
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

// MARK: - Preview

#Preview("App - Small Screen") {
    VStack(spacing: 20) {
        // GitHub 用户
        CommitInfoUserInfoPopup(user: AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"))

        Divider()

        // 普通用户
        CommitInfoUserInfoPopup(user: AvatarUser(name: "John Doe", email: "john@example.com"))

        Divider()

        // 无邮箱用户
        CommitInfoUserInfoPopup(user: AvatarUser(name: "Anonymous", email: ""))
    }
    .padding()
    .frame(width: 800)
}

#Preview("App - Big Screen") {
    HStack(spacing: 20) {
        CommitInfoUserInfoPopup(user: AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"))
            .frame(width: 400)
    }
    .padding()
}
