import SwiftUI

/// 头像堆栈视图组件
/// 显示多个用户的头像，最多显示 3 个，超出部分显示 +N
public struct AvatarStackView: View {
    let users: [AvatarUser]
    let avatarSize: CGFloat
    let maxVisibleCount: Int

    public init(users: [AvatarUser], avatarSize: CGFloat = 24, maxVisibleCount: Int = 3) {
        self.users = users
        self.avatarSize = avatarSize
        self.maxVisibleCount = maxVisibleCount
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(visibleUsers.enumerated()), id: \.element.id) { index, user in
                AvatarView(user: user, size: avatarSize)
                    .offset(x: CGFloat(index) * (avatarSize * 0.6))
            }

            if remainingCount > 0 {
                remainingIndicator
                    .offset(x: CGFloat(visibleUsers.count) * (avatarSize * 0.6))
            }
        }
        .frame(width: calculateWidth(), height: avatarSize)
    }

    /// 可见的用户列表
    private var visibleUsers: [AvatarUser] {
        Array(users.prefix(maxVisibleCount))
    }

    /// 剩余数量
    private var remainingCount: Int {
        max(0, users.count - maxVisibleCount)
    }

    /// 剩余数量指示器
    private var remainingIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.2))

            Text("+\(remainingCount)")
                .font(.system(size: avatarSize * 0.35, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: avatarSize, height: avatarSize)
    }

    /// 计算总宽度
    private func calculateWidth() -> CGFloat {
        let visibleWidth = CGFloat(visibleUsers.count) * (avatarSize * 0.6) + avatarSize
        if remainingCount > 0 {
            return visibleWidth + (avatarSize * 0.6)
        }
        return visibleWidth
    }
}
