import OSLog
import SwiftUI

/// 用户信息弹出视图组件
/// 显示用户的详细信息，包括头像、名称、邮箱等
public struct CommitInfoUserInfoPopup: View {
    /// 是否启用详细日志输出
    public nonisolated static let verbose = false

    /// 要显示的用户信息
    let user: AvatarUser

    /// 显示的头像 URL（从 AvatarService 获取）
    @State private var displayedAvatarURL: URL?

    /// 是否正在加载头像 URL
    @State private var isLoadingAvatarURL: Bool = true

    public init(user: AvatarUser) {
        self.user = user
    }

    public var body: some View {
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
                userInfoRow(
                    title: "用户名",
                    description: user.name,
                    icon: "person"
                )

                Divider()

                // 头像地址（总是显示）
                if isLoadingAvatarURL {
                    userInfoRow(
                        title: "头像地址",
                        description: "加载中...",
                        icon: "safari"
                    )
                } else if let avatarURL = displayedAvatarURL {
                    userInfoRow(
                        title: "头像地址",
                        description: avatarURL.absoluteString,
                        icon: "safari"
                    )
                } else {
                    userInfoRow(
                        title: "头像地址",
                        description: "无",
                        icon: "safari"
                    )
                }

                // 邮箱（如果有）
                if !user.email.isEmpty {
                    Divider()

                    userInfoRow(
                        title: "邮箱",
                        description: user.email,
                        icon: "envelope"
                    )
                }

                // GitHub 主页按钮（如果有）
                if let githubURL = gitHubURL {
                    Divider()

                    userInfoRow(
                        title: "GitHub 主页",
                        description: githubURL.absoluteString,
                        icon: "safari"
                    ) {
                        Button {
                            NSWorkspace.shared.open(githubURL)
                        } label: {
                            Image(systemName: "safari")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 600)
        .onAppear {
            loadAvatarURL()
        }
    }

    private func userInfoRow<Accessory: View>(
        title: String,
        description: String,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            accessory()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func userInfoRow(
        title: String,
        description: String,
        icon: String
    ) -> some View {
        userInfoRow(title: title, description: description, icon: icon) {
            EmptyView()
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
