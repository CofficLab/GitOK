import MagicKit
import SwiftUI
import OSLog

struct BranchStatusTile: View, SuperLog {
    nonisolated static let emoji = "🌿"
    nonisolated static let verbose = false
    
    @EnvironmentObject var data: DataProvider

    @State private var isPresented = false

    private var branchText: String {
        if let branch = data.branch {
            return branch.name
        }
        if data.project == nil {
            return "未选择项目"
        }
        return "无分支"
    }

    var body: some View {
        StatusBarTile(icon: "arrow.branch", onTap: {
            self.isPresented.toggle()
        }) {
            Text(branchText)
        }
        .popover(isPresented: $isPresented) {
            BranchForm()
                .frame(width: 300, height: 500)
        }
        .onProjectDidChangeBranch { eventInfo in
            handleBranchChanged(eventInfo)
        }
        .onApplicationDidBecomeActive {
            handleApplicationDidBecomeActive()
        }
    }
}

// MARK: - Event Handler

extension BranchStatusTile {
    private func handleBranchChanged(_ eventInfo: ProjectEventInfo) {
        // 分支变更事件处理 - DataProvider 已自动更新分支信息
        // 此处可添加额外的 UI 响应逻辑，如动画或通知
        if Self.verbose {
            os_log("\(self.t)Branch changed to \(eventInfo.additionalInfo?["branchName"] as? String ?? "unknown")")
        }
    }

    private func handleApplicationDidBecomeActive() {
        // 应用变为活跃状态时的处理逻辑
        // 分支信息已由 DataProvider 在应用激活时自动刷新
        if Self.verbose {
            os_log("\(self.t)Application became active")
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
        .hideTabPicker()
        .inRootView()
        .frame(width: 1200)
        .frame(height: 1200)
}

