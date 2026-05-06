import MagicKit
import OSLog
import SwiftUI

/// 显示stash状态的Tile组件
struct StashStatusTile: View, SuperLog {
    /// 日志标识符
    nonisolated static let emoji = "📦"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM
    @State private var stashCount = 0
    @State private var isLoading = false
    @State private var isPresented = false

    var body: some View {
        StatusBarTile(icon: "archivebox", onTap: {
            isPresented.toggle()
        }) {
            content
        }
        .help(helpText)
        .popover(isPresented: $isPresented) {
            StashList.shared
                .frame(width: 420, height: 520)
        }
        .onAppear(perform: loadStashCount)
        .onChange(of: vm.project, loadStashCount)
        .onApplicationDidBecomeActive {
            loadStashCount()
        }
        .onProjectDidCommit(perform: onProjectDidCommit)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if stashCount > 0 {
            Text("Stash \(stashCount)")
                .font(.footnote.weight(.medium))
                .foregroundColor(.blue)
                .monospacedDigit()
        } else {
            Text("Stash")
                .foregroundColor(.secondary)
        }
    }

    private var helpText: String {
        if vm.project == nil {
            return "未选择项目"
        }
        if stashCount > 0 {
            return "查看 \(stashCount) 个 stash"
        }
        return "没有 stash，点击打开面板"
    }

    /// 加载stash数量
    private func loadStashCount() {
        guard let project = vm.project else {
            stashCount = 0
            isLoading = false
            return
        }

        isLoading = true

        Task {
            do {
                let stashes = try project.stashList()
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
