import MagicKit
import OSLog
import SwiftUI

/// 显示stash状态的Tile组件
struct StashStatusTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📦"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider
    @EnvironmentObject var vm: ProjectVM
    @State private var stashCount = 0
    @State private var isLoading = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "archivebox")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("\(stashCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(stashCount > 0 ? .blue : .secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.1))
        )
        .onAppear(perform: loadStashCount)
        .onProjectDidCommit(perform: onProjectDidCommit)
    }

    /// 加载stash数量
    private func loadStashCount() {
        guard let project = vm.project else {
            stashCount = 0
            return
        }

        isLoading = true

        Task {
            do {
                let stashes = try await project.stashList()
                await MainActor.run {
                    self.stashCount = stashes.count
                    self.isLoading = false
                }
            } catch {
                if Self.verbose {
                    os_log("\(self.t)❌ Failed to load stash count: \(error)")
                }
                await MainActor.run {
                    self.stashCount = 0
                    self.isLoading = false
                }
            }
        }
    }

    /// 项目提交完成时的事件处理
    func onProjectDidCommit(_ eventInfo: ProjectEventInfo) {
        // 只有stash相关的操作才需要刷新stash数量
        if ["stashSave", "stashApply", "stashPop", "stashDrop"].contains(eventInfo.operation) {
            loadStashCount()
        }
    }
}