import LibGit2Swift
import SwiftUI

/// 提交时间信息显示组件
/// 显示可点击的提交时间信息，支持hover效果和详细信息弹窗
struct CommitTimeInfo: View {
    /// 提交对象
    let commit: GitCommit

    /// 是否显示时间详情弹窗
    @Binding var showingTimePopup: Bool

    var body: some View {
        // 提交时间
        if commit.date != Date(timeIntervalSince1970: 0) {
            AppIconButton(
                systemImage: "clock",
                label: commit.date.fullDateTime,
                tint: DesignTokens.Color.semantic.textSecondary,
                size: .regular
            ) {
                showingTimePopup = true
            }
            .help("点击查看完整时间信息")
            .popover(isPresented: $showingTimePopup, arrowEdge: .bottom) {
                CommitTimePopup(commit: commit)
                    .frame(width: 350)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }
}

// MARK: - Preview

#Preview("Commit Time Info") {
    @State var showingTimePopup = false

    return CommitTimeInfo(
        commit: GitCommit(
            id: "abc123",
            hash: "abc123def456789abcdef0123456789abcdef0123",
            author: "Test Author",
            email: "test@example.com",
            date: Date(),
            message: "Test commit",
            body: "Test body",
            refs: [],
            tags: []
        ),
        showingTimePopup: $showingTimePopup
    )
}
