import MagicKit
import OSLog
import SwiftUI

/// 显示冲突状态的Tile组件
struct ConflictStatusTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "⚔️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataProvider
    @State private var conflictCount = 0
    @State private var isLoading = false
    @State private var isMerging = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isMerging ? "exclamationmark.triangle" : "checkmark.circle")
                .font(.system(size: 12))
                .foregroundColor(isMerging ? .red : .green)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else if isMerging {
                Text("\(conflictCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isMerging ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        )
        .onAppear(perform: loadConflictStatus)
        .onProjectDidMerge(perform: onProjectDidMerge)
    }

    /// 加载冲突状态
    private func loadConflictStatus() {
        guard let project = data.project else {
            conflictCount = 0
            isMerging = false
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
        loadConflictStatus()
    }
}