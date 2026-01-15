import MagicKit
import MagicUI
import OSLog
import SwiftUI

// MARK: - UserInfo

/// 可点击的用户信息组件
/// 点击时显示用户详细信息弹窗
struct UserInfo: View, SuperLog {
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
                    .frame(width: 800)
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
    HStack(spacing: 20) {
        UserInfo(
            users: [
                AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"),
            ],
            avatarSize: 18
        )

        UserInfo(
            users: [
                AvatarUser(name: "Alice", email: "alice@example.com"),
                AvatarUser(name: "Bob", email: "bob@example.com"),
            ],
            avatarSize: 18
        )
    }
    .padding()
}

#Preview("App - Big Screen") {
    VStack(spacing: 20) {
        UserInfo(
            users: [
                AvatarUser(name: "octocat", email: "octocat@users.noreply.github.com"),
            ],
            avatarSize: 24
        )

        UserInfo(
            users: [
                AvatarUser(name: "Alice", email: "alice@example.com"),
                AvatarUser(name: "Bob", email: "bob@example.com"),
                AvatarUser(name: "Charlie", email: "charlie@example.com"),
            ],
            avatarSize: 24
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
