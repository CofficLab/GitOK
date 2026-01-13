import LibGit2Swift
import MagicKit
import SwiftUI

/// 显示远程仓库信息的视图组件
struct RemoteInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "☁️"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 远程仓库列表
    let remotes: [GitRemote]

    var body: some View {
        MagicSettingSection(title: "远程仓库", titleAlignment: .leading) {
            VStack(spacing: 0) {
                ForEach(remotes) { remote in
                    MagicSettingRow(
                        title: remote.name,
                        description: remote.url,
                        icon: .iconCloud
                    ) {
                        // 远程仓库信息通常不需要操作按钮
                    }

                    if remote != remotes.last {
                        Divider()
                    }
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