import LibGit2Swift
import MagicKit
import OSLog
import SwiftUI

/// 未推送提交状态栏图标
/// 显示当前项目的未推送提交数量，点击可查看详情
struct UnpushedStatusTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📤"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 插件提供者环境对象（用于获取插件实例）
    @EnvironmentObject var p: PluginVM

    /// 未推送提交数量（从 ProjectVM 获取）
    @EnvironmentObject var vm: ProjectVM

    @State private var isPresented = false

    private var unpushedCount: Int {
        vm.unpushedCommitsCount
    }

    private var displayText: String {
        if unpushedCount == 0 {
            return String(localized: "已同步", table: "UnpushedStatus")
        } else if unpushedCount == 1 {
            return String(localized: "1 个未推送", table: "UnpushedStatus")
        } else {
            return String(localized: "\(unpushedCount) 个未推送", table: "UnpushedStatus")
        }
    }

    private var statusIcon: String {
        if unpushedCount == 0 {
            return "checkmark.circle.fill"
        } else {
            return "arrow.up.circle.fill"
        }
    }

    var body: some View {
        StatusBarTile(icon: statusIcon, onTap: {
            self.isPresented.toggle()
        }) {
            Text(displayText)
        }
        .popover(isPresented: $isPresented) {
            UnpushedCommitsDetailView()
                .frame(width: 400, height: 500)
        }
        .onProjectDidChangeBranch { _ in
            refreshStatus()
        }
        .onProjectDidCommit { _ in
            refreshStatus()
        }
        .onProjectDidPush { _ in
            refreshStatus()
        }
        .onProjectDidPull { _ in
            refreshStatus()
        }
        .onApplicationDidBecomeActive {
            refreshStatus()
        }
    }

    private func refreshStatus() {
        guard let plugin = p.plugins.first(where: { $0.instanceLabel == "UnpushedStatusPlugin" }) as? UnpushedStatusPlugin else {
            return
        }
        plugin.refresh()
    }
}

// MARK: - UnpushedCommitsDetailView

/// 未推送提交详情视图
struct UnpushedCommitsDetailView: View, SuperLog {
    nonisolated static let emoji = "📤"
    nonisolated static let verbose = false

    @EnvironmentObject var vm: ProjectVM

    @State private var commits: [GitCommit] = []
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            HStack {
                Text("未推送提交", tableName: "UnpushedStatus")
                    .font(.headline)
                Spacer()
                Button("刷新") {
                    loadUnpushedCommits()
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            // 提交列表
            if loading {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            } else if commits.isEmpty {
                Spacer()
                Text("没有未推送的提交", tableName: "UnpushedStatus")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(commits, id: \.hash) { commit in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message.firstLine ?? "")
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(2)

                        HStack {
                            Text(commit.hash.prefix(7))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(commit.author.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            loadUnpushedCommits()
        }
    }

    private func loadUnpushedCommits() {
        guard let project = vm.project else { return }

        loading = true

        Task.detached(priority: .userInitiated) {
            do {
                let unpushed = try await project.getUnPushedCommits()

                await MainActor.run {
                    self.commits = unpushed
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.loading = false
                }
                os_log(.error, "\(Self.t)❌ Failed to load unpushed commits: \(error)")
            }
        }
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