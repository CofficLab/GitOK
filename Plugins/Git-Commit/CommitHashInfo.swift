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

    var body: some View {
        // Hash 信息
        if !commit.hash.isEmpty {
            AppIconButton(
                systemImage: "number",
                label: String(commit.hash.prefix(8)),
                tint: DesignTokens.Color.semantic.textSecondary,
                size: .regular
            ) {
                showingHashPopup = true
            }
            .help("点击查看完整 Hash 信息")
            .padding(.trailing, 26)
            .overlay(alignment: .trailing) {
                AppIconButton(
                    systemImage: isCopied ? "checkmark.circle" : "doc.on.doc",
                    tint: isCopied ? .green : DesignTokens.Color.semantic.textSecondary,
                    size: .compact,
                    isActive: isCopied
                ) {
                    commit.hash.copy()
                    withAnimation(.spring()) {
                        isCopied = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.spring()) {
                            isCopied = false
                        }
                    }
                }
                .padding(.trailing, 2)
                .help(isCopied ? "已复制" : "复制完整 Hash")
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
