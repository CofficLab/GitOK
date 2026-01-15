import LibGit2Swift
import SwiftUI

/// 提交正文信息显示组件
/// 显示提交的详细描述信息，支持文本选择
struct CommitBodyInfo: View {
    /// 提交对象
    let commit: GitCommit

    var body: some View {
        // Commit body（如果有）
        if !commit.body.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                Text(commit.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(10)
                    .textSelection(.enabled)

                Spacer()
            }

            Divider()
        }
    }
}

// MARK: - Preview

#Preview("Commit Body Info - With Body") {
    VStack {
        CommitBodyInfo(commit: GitCommit(
            id: "abc123",
            hash: "abc123def456789abcdef0123456789abcdef0123",
            author: "Test Author",
            email: "test@example.com",
            date: Date(),
            message: "Test commit",
            body: "This is a detailed commit body that provides more information about the changes made in this commit. It can span multiple lines and provide context for the changes.",
            refs: [],
            tags: []
        ))
    }
    .padding()
}

#Preview("Commit Body Info - Empty Body") {
    VStack {
        CommitBodyInfo(commit: GitCommit(
            id: "abc123",
            hash: "abc123def456789abcdef0123456789abcdef0123",
            author: "Test Author",
            email: "test@example.com",
            date: Date(),
            message: "Test commit",
            body: "",
            refs: [],
            tags: []
        ))
    }
    .padding()
}