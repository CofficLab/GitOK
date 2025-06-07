import MagicCore
import SwiftUI

/**
 * 展示 Commit 详细信息的视图组件
 */
struct CommitDetailView: View, SuperEvent {
    @EnvironmentObject var data: DataProvider
    @State private var isCopied: Bool = false
    
    let commit: GitCommit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !commit.isHead {
                HStack {
                    // Commit 图标
                    Image(systemName: commit.isHead ? "circle.fill" : "smallcircle.filled.circle")
                        .foregroundColor(commit.isHead ? .green : .blue)
                        .font(.system(size: 12))

                    // Commit 消息
                    Text(commit.message)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()
                }

                HStack(spacing: 16) {
                    // 作者信息
                    if !commit.author.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            Text(commit.author)
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

                    Spacer()
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
            } else {
                CommitForm()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
        .onChange(of: data.project) { self.onProjectChanged() }
        .onReceive(nc.publisher(for: .appWillBecomeActive), perform: onAppWillBecomeActive)
    }

    private var background: some View {
        ZStack {
            if commit.isHead {
                MagicBackground.blueberry.opacity(0.12)
            } else {
                MagicBackground.orange.opacity(0.15)
            }
        }
    }
}

// MARK: - Event

extension CommitDetailView {
    func onAppWillBecomeActive(_ notification: Notification) {
        
    }

    func onProjectChanged() {
        
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 600)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
