import MagicKit
import LibGit2Swift
import SwiftUI

/// 提交信息显示视图组件
/// 包含提交消息、作者信息、时间和 Hash 等详细信息
struct CommitInfoView: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📋"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 提交对象
    let commit: GitCommit

    /// 是否已复制到剪贴板
    @State private var isCopied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Commit 图标
                Image(systemName: "smallcircle.filled.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))

                // Commit 消息
                Text(commit.message)
                    .font(.headline)
                    .lineLimit(2)

                Spacer()
            }

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
            }

            HStack(spacing: 16) {
                // 作者信息
                if !commit.author.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(commit.allAuthors)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 提交时间
                if commit.date != Date(timeIntervalSince1970: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(commit.date.fullDateTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Hash 信息
                if !commit.hash.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        Text(commit.hash.prefix(8))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
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

                        Spacer()
                    }
                }

                Spacer()
            }
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 600)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
