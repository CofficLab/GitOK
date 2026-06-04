import OSLog
import GitOKUI
import SwiftUI

/// 头像视图组件
public struct AvatarView: View {
    /// 是否启用详细日志输出
    public nonisolated static let verbose = false
    let user: AvatarUser
    let size: CGFloat

    private let avatarService = AvatarService.shared
    @State private var avatarURL: URL?

    public init(user: AvatarUser, size: CGFloat = 32) {
        self.user = user
        self.size = size
    }

    public var body: some View {
        Group {
            if let url = avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    /// 图片加载成功
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    /// 图片加载失败
                    case .failure:
                        defaultAvatar
                    /// 图片加载中
                    case .empty:
                        AppLoadingOverlay(size: .small)
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: user) {
            await loadAvatar()
        }
    }
}

// MARK: - View

extension AvatarView {
    /// 默认头像（首字母或默认图标）
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.2))

            /// 显示用户名的首字母
            if let firstLetter = user.name.first {
                Text(String(firstLetter))
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                /// 用户名为空时显示默认图标
                Image(systemName: "person.circle")
                    .font(.system(size: size * 0.8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Private Helpers

extension AvatarView {
    /// 异步加载用户头像
    /// 首先尝试从AvatarService获取头像，失败时回退到Gravatar
    private func loadAvatar() async {
        if Self.verbose {
            os_log("开始加载头像: \(user.name) <\(user.email)>")
        }

        let url = await avatarService.getAvatarURL(name: user.name, email: user.email)
        guard Task.isCancelled == false else { return }
        avatarURL = url
    }
}
