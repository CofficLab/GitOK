import MagicKit
import OSLog
import SwiftUI

/// 显示冲突状态的Tile组件
struct ConflictStatusTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚔️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @State private var conflictCount = 0
    @State private var isLoading = false
    @State private var isMerging = false
    @State private var isPresented = false

    var body: some View {
        StatusBarTile(icon: iconName, onTap: {
            isPresented.toggle()
        }) {
            content
        }
        .help(helpText)
        .popover(isPresented: $isPresented) {
            ConflictResolverList.shared
                .frame(width: 440, height: 560)
        }
        .onAppear(perform: loadConflictStatus)
        .onChange(of: vm.project, loadConflictStatus)
        .onApplicationDidBecomeActive {
            loadConflictStatus()
        }
        .onProjectDidMerge(perform: onProjectDidMerge)
        .onProjectDidAddFiles(perform: onProjectDidAddFiles)
    }

    private var iconName: String {
        isMerging ? "exclamationmark.triangle.fill" : "checkmark.circle"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if isMerging {
            Text("冲突 \(conflictCount)")
                .font(.footnote.weight(.medium))
                .foregroundColor(.red)
                .monospacedDigit()
        } else {
            Text("合并正常")
                .foregroundColor(.secondary)
        }
    }

    private var helpText: String {
        if vm.project == nil {
            return "未选择项目"
        }
        if isMerging {
            return "存在 \(conflictCount) 个冲突文件，点击打开冲突处理"
        }
        return "当前没有合并冲突"
    }

    /// 加载冲突状态
    private func loadConflictStatus() {
        guard let project = vm.project else {
            conflictCount = 0
            isMerging = false
            isLoading = false
            return
        }

        isLoading = true

        Task {
            do {
                let merging = try await project.isMerging()
                let conflicts = merging ? try await project.getMergeConflictFiles() : []

                await MainActor.run {
                    self.isMerging = merging
                    self.conflictCount = conflicts.count
                    self.isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load conflict status: \(error)")
                }
                await MainActor.run {
                    self.conflictCount = 0
                    self.isMerging = false
                    self.isLoading = false
                }
            }
        }
    }

    /// 项目合并事件处理
    func onProjectDidMerge(_ eventInfo: ProjectEventInfo) {
        handleRefreshTrigger(notificationName: .projectDidMerge)
    }

    /// 文件暂存后可能改变冲突状态
    func onProjectDidAddFiles(_ eventInfo: ProjectEventInfo) {
        handleRefreshTrigger(notificationName: .projectDidAddFiles)
    }

    private func handleRefreshTrigger(notificationName: Notification.Name) {
        guard ProjectEventRefreshRules.shouldRefreshConflictStatus(for: notificationName) else { return }
        loadConflictStatus()
    }
}
