import OSLog
import SwiftUI

/// 可点击的用户信息组件
/// 点击时显示用户详细信息弹窗
public struct CommitInfoUser: View {
    /// 是否启用详细日志输出
    public nonisolated static let verbose = false

    /// 提交对象，用于解析用户信息
    let author: String

    /// 解析出的用户信息（基于当前commit计算）
    private var avatarUser: AvatarUser? {
        parseAuthorInfo()
    }

    /// 是否显示用户信息弹窗
    @State private var showingPopup = false

    /// 初始化可点击用户信息组件
    /// - Parameter author: 提交作者字符串，可为 "name <email>" 或 "name"
    public init(author: String) {
        self.author = author
    }

    public var body: some View {
        /// 如果作者信息为空，不显示任何内容
        if author.isEmpty {
            EmptyView()
        } else {
            Button {
                showingPopup = true
            } label: {
                Label(avatarUser?.name ?? CommitLocalization.string("Unknown"), systemImage: "person.circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help(CommitLocalization.string("Click to view user info"))
            .popover(isPresented: $showingPopup, arrowEdge: .bottom) {
                /// 直接使用 avatarUser
                if let user = avatarUser {
                    CommitInfoUserInfoPopup(user: user)
                        .frame(width: 600)
                        .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    /// 只有在真的没有用户时才显示这个
                    Text("User info not found")
                        .frame(width: 200, height: 100)
                }
            }
        }
    }
}

// MARK: - Private Helpers

extension CommitInfoUser {
    /// 解析提交的作者信息
    private func parseAuthorInfo() -> AvatarUser? {
        if Self.verbose {
            os_log("开始解析作者信息: \(author)")
        }

        /// author 格式可能是 "name <email>" 或只是 "name"
        if let emailRange = author.range(of: "<([^>]+)>", options: .regularExpression) {
            /// 有邮箱
            let emailStartIndex = author.index(emailRange.lowerBound, offsetBy: 1)
            let emailEndIndex = author.index(emailRange.upperBound, offsetBy: -1)
            let authorEmail = String(author[emailStartIndex ..< emailEndIndex])

            let nameEndIndex = author.index(emailRange.lowerBound, offsetBy: -2)
            let authorName = String(author[..<nameEndIndex]).trimmingCharacters(in: .whitespaces)

            let user = AvatarUser(name: authorName, email: authorEmail)
            if Self.verbose {
                os_log("成功解析带邮箱的作者: \(authorName) <\(authorEmail)>")
            }
            return user
        } else {
            /// 没有邮箱，使用 author 作为 name
            let user = AvatarUser(name: author, email: "")
            return user
        }
    }
}
