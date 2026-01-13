import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示项目不存在时删除选项的视图组件
struct ProjectNotFoundView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "⚠️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    var body: some View {
        VStack(spacing: 12) {
            BtnDeleteProject(project: project)
                .frame(width: 200, height: 40)
        }
        .padding(.vertical, 20)
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
