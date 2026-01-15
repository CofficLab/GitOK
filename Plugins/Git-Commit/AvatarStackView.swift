import SwiftUI

/// 头像堆栈视图组件
/// 显示多个用户的头像，最多显示 3 个，超出部分显示 +N
struct AvatarStackView: View {
    let users: [AvatarUser]
    let avatarSize: CGFloat
    let maxVisibleCount: Int

    init(users: [AvatarUser], avatarSize: CGFloat = 24, maxVisibleCount: Int = 3) {
        self.users = users
        self.avatarSize = avatarSize
        self.maxVisibleCount = maxVisibleCount
    }

    var body: some View {
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

#Preview("Avatar Stack View") {
    VStack(spacing: 20) {
        // 单个头像
        AvatarStackView(
            users: [AvatarUser(name: "John Doe", email: "john@example.com")],
            avatarSize: 32
        )

        // 两个头像
        AvatarStackView(
            users: [
                AvatarUser(name: "Alice", email: "alice@example.com"),
                AvatarUser(name: "Bob", email: "bob@example.com")
            ],
            avatarSize: 32
        )

        // 三个头像
        AvatarStackView(
            users: [
                AvatarUser(name: "Charlie", email: "charlie@example.com"),
                AvatarUser(name: "David", email: "david@example.com"),
                AvatarUser(name: "Eve", email: "eve@example.com")
            ],
            avatarSize: 32
        )

        // 多个头像（显示 +N）
        AvatarStackView(
            users: [
                AvatarUser(name: "Frank", email: "frank@example.com"),
                AvatarUser(name: "Grace", email: "grace@example.com"),
                AvatarUser(name: "Henry", email: "henry@example.com"),
                AvatarUser(name: "Ivy", email: "ivy@example.com"),
                AvatarUser(name: "Jack", email: "jack@example.com")
            ],
            avatarSize: 32
        )

        // 不同尺寸
        HStack(spacing: 16) {
            AvatarStackView(
                users: [
                    AvatarUser(name: "Small", email: "small@example.com"),
                    AvatarUser(name: "Test", email: "test@example.com")
                ],
                avatarSize: 20
            )

            AvatarStackView(
                users: [
                    AvatarUser(name: "Medium", email: "medium@example.com"),
                    AvatarUser(name: "Test", email: "test@example.com")
                ],
                avatarSize: 32
            )

            AvatarStackView(
                users: [
                    AvatarUser(name: "Large", email: "large@example.com"),
                    AvatarUser(name: "Test", email: "test@example.com")
                ],
                avatarSize: 48
            )
        }
    }
    .padding()
}
