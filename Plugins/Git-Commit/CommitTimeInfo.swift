import LibGit2Swift
import SwiftUI

/// 提交时间信息显示组件
/// 显示可点击的提交时间信息，支持hover效果和详细信息弹窗
struct CommitTimeInfo: View {
    /// 提交对象
    let commit: GitCommit

    /// 是否显示时间详情弹窗
    @Binding var showingTimePopup: Bool

    /// 是否正在悬停
    @State private var isHovering = false

    var body: some View {
        // 提交时间
        if commit.date != Date(timeIntervalSince1970: 0) {
            Button(action: {
                showingTimePopup = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text(commit.date.fullDateTime)
                        .font(.caption)
                        .foregroundColor(isHovering ? .primary : .secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering ? Color.secondary.opacity(0.2) : Color.clear)
                )
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            .buttonStyle(.plain)
            .help("点击查看完整时间信息")
            .onHover { hovering in
                isHovering = hovering
            }
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