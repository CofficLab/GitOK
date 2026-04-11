import MagicKit
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

    /// 是否正在加载头像 URL
    @State private var isLoadingAvatarURL: Bool = true

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

            // 信息列表
            VStack(spacing: 0) {
                // 用户名
                MagicSettingRow(
                    title: "用户名",
                    description: user.name,
                    icon: .iconUser
                ) {
                    EmptyView()
                }

                Divider()

                // 头像地址（总是显示）
                if isLoadingAvatarURL {
                    MagicSettingRow(
                        title: "头像地址",
                        description: "加载中...",
                        icon: .iconSafari
                    ) {
                        EmptyView()
                    }
                } else if let avatarURL = displayedAvatarURL {
                    MagicSettingRow(
                        title: "头像地址",
                        description: avatarURL.absoluteString,
                        icon: .iconSafari
                    ) {
                        EmptyView()
                    }
                } else {
                    MagicSettingRow(
                        title: "头像地址",
                        description: "无",
                        icon: .iconSafari
                    ) {
                        EmptyView()
                    }
                }

                // 邮箱（如果有）
                if !user.email.isEmpty {
                    Divider()

                    MagicSettingRow(
                        title: "邮箱",
                        description: user.email,
                        icon: .iconMail
                    ) {
                        EmptyView()
                    }
                }

                // GitHub 主页按钮（如果有）
                if let githubURL = gitHubURL {
                    Divider()

                    AppSettingRow(
                        title: "GitHub 主页",
                        description: githubURL.absoluteString,
                        icon: .iconSafari
                    ) {
                        AppIconButton(systemImage: "safari", size: .regular) {
                            NSWorkspace.shared.open(githubURL)
                        }
                    }
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
            let url = await AvatarService.shared.getAvatarURL(name: user.name, email: user.email)
            await MainActor.run {
                self.displayedAvatarURL = url
                self.isLoadingAvatarURL = false
            }
        }
    }
}

// MARK: - View

extension CommitInfoUserInfoPopup {
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
