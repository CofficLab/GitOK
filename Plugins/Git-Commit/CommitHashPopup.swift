import LibGit2Swift
import SwiftUI

/// 提交Hash详情弹出组件
/// 显示提交的完整Hash信息，包括多种格式和统计信息
struct CommitHashPopup: View {
    /// 要显示Hash的提交对象
    let commit: GitCommit

    /// 复制状态绑定（从父视图传递）
    @Binding var isCopied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            Text("提交 Hash 详情")
                .font(.headline)
                .foregroundColor(.primary)

            Divider()

            // Hash 信息列表
            VStack(spacing: 12) {
                // 完整 Hash
                hashInfoRow(
                    title: "完整 Hash",
                    value: commit.hash,
                    icon: "number.circle.fill",
                    selectable: true,
                    showCopyButton: true
                )

                // 短 Hash (8位)
                hashInfoRow(
                    title: "短 Hash (8位)",
                    value: String(commit.hash.prefix(8)),
                    icon: "number.circle",
                    selectable: true,
                    showCopyButton: true
                )

                // Hash 长度
                hashInfoRow(
                    title: "Hash 长度",
                    value: "\(commit.hash.count) 字符",
                    icon: "ruler",
                    selectable: false,
                    showCopyButton: false
                )

                // Hash 前缀检查
                if commit.hash.hasPrefix("0") {
                    hashInfoRow(
                        title: "前缀特征",
                        value: "以 0 开头",
                        icon: "exclamationmark.triangle",
                        selectable: false,
                        showCopyButton: false
                    )
                }
            }
        }
        .padding(20)
    }

    /// Hash信息行组件
    /// - Parameters:
    ///   - title: 信息标题
    ///   - value: 信息值
    ///   - icon: 系统图标名称
    ///   - selectable: 是否可选择文本
    ///   - showCopyButton: 是否显示复制按钮
    /// - Returns: 配置好的视图
    private func hashInfoRow(title: String, value: String, icon: String, selectable: Bool, showCopyButton: Bool) -> some View {
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

            if showCopyButton {
                Button(action: {
                    value.copy()
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
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isCopied ? .green : .secondary)
                        .scaleEffect(isCopied ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
                .help(isCopied ? "已复制" : "复制到剪贴板")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview("Commit Hash Popup") {
    @State var isCopied = false

    CommitHashPopup(
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
        isCopied: $isCopied
    )
    .frame(width: 450)
}