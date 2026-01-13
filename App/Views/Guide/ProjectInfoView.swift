import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示当前项目信息的视图组件
struct ProjectInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📁"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    var body: some View {
        MagicSettingSection(title: "当前项目", titleAlignment: .leading) {
            VStack(spacing: 0) {
                MagicSettingRow(
                    title: project.title,
                    description: project.path,
                    icon: .iconFolder
                ) {
                    MagicButton.simple {
                        project.url.openFolder()
                    }
                    .magicIcon(.iconFinder)
                }
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