import MagicCore
import SwiftUI

// MARK: - BranchStatusTile

struct BranchStatusTile: View {
    @EnvironmentObject var data: DataProvider

    @State private var isPresented = false

    private let verbose = false

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
        if verbose {
            os_log("BranchStatusTile: Branch changed to \(eventInfo.additionalInfo?["branchName"] as? String ?? "unknown")")
        }
    }

    private func handleApplicationDidBecomeActive() {
        // 应用变为活跃状态时的处理逻辑
        // 分支信息已由 DataProvider 在应用激活时自动刷新
        if verbose {
            os_log("BranchStatusTile: Application became active")
        }
    }
}

// MARK: - Preview

#if os(macOS)
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
#endif

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

