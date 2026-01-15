import LibGit2Swift
import LibGit2Swift
import SwiftUI

/// 提交时间详情弹出组件
/// 显示提交的完整时间信息，包括多种时间格式
struct CommitTimePopup: View {
    /// 要显示时间的提交对象
    let commit: GitCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("提交时间详情")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // 时间信息列表
            VStack(spacing: 12) {
                // 完整日期时间
                timeInfoRow(
                    title: "完整时间",
                    value: commit.date.fullDateTime,
                    icon: "clock.fill"
                )

                // 相对时间
                timeInfoRow(
                    title: "相对时间",
                    value: commit.date.formatted(.relative(presentation: .named)),
                    icon: "clock.arrow.circlepath"
                )

                // ISO 格式
                timeInfoRow(
                    title: "ISO 格式",
                    value: ISO8601DateFormatter().string(from: commit.date),
                    icon: "calendar.badge.clock",
                    selectable: true
                )

                // Unix 时间戳
                timeInfoRow(
                    title: "Unix 时间戳",
                    value: "\(Int(commit.date.timeIntervalSince1970))",
                    icon: "number.circle",
                    selectable: true
                )
            }
        }
        .padding(20)
    }

    /// 时间信息行组件
    /// - Parameters:
    ///   - title: 信息标题
    ///   - value: 信息值
    ///   - icon: 系统图标名称
    ///   - selectable: 是否可选择文本
    /// - Returns: 配置好的视图
    private func timeInfoRow(title: String, value: String, icon: String, selectable: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.system(size: 16))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectable {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                } else {
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Commit Time Popup") {
    CommitTimePopup(commit: GitCommit(
        id: "abc123",
        hash: "abc123def456789abcdef0123456789abcdef0123",
        author: "Test Author",
        email: "test@example.com",
        date: Date(),
        message: "Test commit",
        body: "Test body",
        refs: [],
        tags: []
    ))
    .frame(width: 350)
}