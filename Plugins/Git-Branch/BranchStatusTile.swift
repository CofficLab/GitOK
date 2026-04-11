import MagicKit
import LibGit2Swift
import SwiftUI
import OSLog

struct BranchStatusTile: View, SuperLog {
    nonisolated static let emoji = "🌿"
    nonisolated static let verbose = false
    
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var isPresented = false

    private var branchText: String {
        if let branch = data.branch {
            return branch.name
        }
        if vm.project == nil {
            return String(localized: "未选择项目", table: "GitBranch")
        }
        return String(localized: "无分支", table: "GitBranch")
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
        // 分支变更事件处理
        guard let newBranchName = eventInfo.additionalInfo?["branchName"] as? String else {
            if Self.verbose {
                os_log(.error, "\(self.t)No branch name found in event info")
            }
            return
        }

        // 检查 data 中的分支是否与事件中的分支一致
        if data.branch?.name != newBranchName {
            if Self.verbose {
                os_log("\(self.t)Branch mismatch detected. Data branch: \(data.branch?.name ?? "nil"), Event branch: \(newBranchName)")
            }

            // 尝试从项目获取最新的分支对象
            do {
                if let newBranch = try eventInfo.project.getCurrentBranch(),
                   newBranch.name == newBranchName {

                    // 更新 data 中的分支
                    try? data.setBranch(newBranch, project: vm.project)

                    if Self.verbose {
                        os_log("\(self.t)Updated data branch to \(newBranchName)")
                    }
                } else {
                    if Self.verbose {
                        os_log(.error, "\(self.t)Failed to get current branch or branch name mismatch")
                    }
                }
            } catch {
                if Self.verbose {
                    os_log(.error, "\(self.t)Failed to update branch: \(error.localizedDescription)")
                }
            }
        } else {
            if Self.verbose {
                os_log("\(self.t)Branch already in sync: \(newBranchName)")
            }
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

