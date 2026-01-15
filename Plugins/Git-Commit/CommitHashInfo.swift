import LibGit2Swift
import SwiftUI

/// 提交Hash信息显示组件
/// 显示可点击的提交Hash信息，支持hover效果和详细信息弹窗
struct CommitHashInfo: View {
    /// 提交对象
    let commit: GitCommit

    /// 是否已复制到剪贴板
    @Binding var isCopied: Bool

    /// 是否显示Hash详情弹窗
    @Binding var showingHashPopup: Bool

    /// 是否正在悬停
    @State private var isHovering = false

    var body: some View {
        // Hash 信息
        if !commit.hash.isEmpty {
            Button(action: {
                showingHashPopup = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text(commit.hash.prefix(8))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(isHovering ? .primary : .secondary)
                        .textSelection(.enabled)

                    // 复制按钮
                    Button(action: {
                        commit.hash.copy()
                        withAnimation(.spring()) {
                            isCopied = true
                        }

                        // 1.5秒后重置状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.spring()) {
                                isCopied = false
                            }
                        }
                    }) {
                        Image(systemName: isCopied ? "checkmark.circle" : "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(isCopied ? .green : .secondary)
                            .scaleEffect(isCopied ? 1.2 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .help(isCopied ? "已复制" : "复制完整 Hash")
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
            .help("点击查看完整 Hash 信息")
            .onHover { hovering in
                isHovering = hovering
            }
            .popover(isPresented: $showingHashPopup, arrowEdge: .bottom) {
                CommitHashPopup(commit: commit, isCopied: $isCopied)
                    .frame(width: 450)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

// MARK: - Preview

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
