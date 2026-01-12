import MagicKit
import OSLog
import SwiftData
import SwiftUI

/// 非 Git 项目提示视图
/// 当当前目录不是 Git 仓库时显示此视图
struct NotGit: View, SuperLog, SuperThread, SuperEvent {
    /// emoji 标识符
    nonisolated static let emoji = "⚠️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false
    var body: some View {
        GuideView(
            systemImage: "exclamationmark.triangle",
            title: NSLocalizedString("not_git_project", bundle: .main, comment: "")
        )
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
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
