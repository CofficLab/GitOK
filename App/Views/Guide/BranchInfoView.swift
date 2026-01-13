import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示当前分支信息的视图组件
struct BranchInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "🌿"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 分支实例
    let branch: GitBranch

    var body: some View {
        MagicSettingSection(title: "当前分支", titleAlignment: .leading) {
            MagicSettingRow(
                title: branch.name,
                description: "当前检出的分支",
                icon: .iconLog
            ) {
                // 分支信息通常不需要操作按钮
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