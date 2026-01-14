
import MagicKit
import LibGit2Swift
import SwiftUI

/// 提交记录行视图组件
/// 显示单个 Git 提交的详细信息，包括消息、作者、时间等
struct CommitRow: View, SuperThread {
    /// 环境对象：数据提供者
    @EnvironmentObject var data: DataProvider

    /// 提交对象
    let commit: GitCommit

    /// 是否未同步到远程
    let isUnpushed: Bool

    /// 标签文本
    @State private var tag: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                data.setCommit(commit)
            }) {
                ZStack(alignment: .bottomTrailing) {
                    // 主要内容
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            // 第一行：提交消息标题
                            HStack {
                                Text(commit.message)
                                    .lineLimit(1)
                                    .font(.system(size: 13))
                                Spacer()
                            }

                            // 第二行：所有作者（包括 Co-Authored-By）
                            HStack {
                                Text(commit.allAuthors)
                                    .padding(.vertical, 1)
                                    .lineLimit(1)

                                // 相对时间标签
                                Text(commit.date.smartRelativeTime)
                                    .padding(.vertical, 1)
                                    .padding(.horizontal, 1)

                                Spacer()
                            }
                            .padding(.vertical, 1)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                            // 第三行：提交时间（完整）
                            HStack {
                                Text(commit.date.fullDateTime)
                                    .lineLimit(1)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 25)
                        .contentShape(Rectangle())
                    }

                    // 右下角背景元素
                    HStack(spacing: 4) {
                        // 未推送到远程的图标作为背景
                        if isUnpushed {
                            Image(systemName: .iconUpload)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.6))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(0)
                                .help("尚未推送到远程仓库")
                        }

                        // 标签作为右下角背景
                        if !tag.isEmpty {
                            Text(tag)
                                .font(.system(size: 12))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(0)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(data.commit == self.commit ? Color.accentColor.opacity(0.1) : Color.clear)
            .onAppear(perform: onAppear)
            .onNotification(.appWillBecomeActive, onAppWillBecomeActive)
            .onProjectDidCommit(perform: onGitCommitSuccess)

            Divider()
        }
    }

    /// 异步加载commit的tag信息
    private func loadTag() {
        guard let project = data.project else {
            self.tag = ""
            return
        }

        do {
            let tags = try project.getTags(commit: self.commit.hash)

            self.tag = tags.first ?? ""
        } catch {
            // 获取tag失败时不显示tag
        }
    }
}

// MARK: - Event

extension CommitRow {
    func onAppear() {
        self.bg.async {
            loadTag()
        }
    }

    func onAppWillBecomeActive(_ n: Notification) {
        loadTag()
    }

    func onGitCommitSuccess(_ eventInfo: ProjectEventInfo) {
        loadTag()
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}
