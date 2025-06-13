import MagicCore
import SwiftUI

struct CommitRow: View, SuperThread {
    @EnvironmentObject var data: DataProvider

    let commit: GitCommit

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
                            // 第一行：提交消息
                            HStack {
                                Text(commit.message)
                                    .lineLimit(1)
                                    .font(.system(size: 13))
                                Spacer()
                            }

                            // 第二行：提交人和提交时间
                            HStack {
                                Text(commit.author)
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
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 25)
                        .contentShape(Rectangle())
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
            .buttonStyle(PlainButtonStyle())
            .background(data.commit == self.commit ? Color.accentColor.opacity(0.1) : Color.clear)
            .onAppear(perform: onAppear)
            .onNotification(.appWillBecomeActive, onAppWillBecomeActive)
            .onNotification(.projectDidCommit, onGitCommitSuccess)

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

    func onGitCommitSuccess(_ n: Notification) {
        loadTag()
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 700)
    .frame(height: 700)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
