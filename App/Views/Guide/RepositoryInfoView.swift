import Foundation
import LibGit2Swift
import MagicKit
import MagicUI
import OSLog
import SwiftUI

/// 显示仓库信息的视图组件（包含本地和远程仓库）
struct RepositoryInfoView: View, SuperLog {
    /// emoji 标识符
    nonisolated static let emoji = "📁"

    /// 是否启用详细日志输出
    nonisolated static let verbose = false

    /// 项目实例
    let project: Project

    /// 远程仓库列表
    let remotes: [GitRemote]

    /// 当前分支（可选）
    let branch: GitBranch?

    var body: some View {
        MagicSettingSection(title: "仓库信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 本地仓库位置
                localRepositoryRow

                if !remotes.isEmpty {
                    Divider()

                    // 远程仓库位置
                    remoteRepositoryRow
                }

                if let branch = branch {
                    Divider()

                    // 当前分支
                    currentBranchRow(branch: branch)
                }
            }
        }
    }

    // MARK: - View Components

    private var localRepositoryRow: some View {
        MagicSettingRow(
            title: "本地仓库",
            description: project.path,
            icon: .iconFolder
        ) {
            MagicButton.simple {
                project.url.openFolder()
            }
            .magicIcon(.iconFinder)
            .magicShapeVisibility(.onHover)
            .magicShape(.circle)
        }
    }

    private var remoteRepositoryRow: some View {
        MagicSettingRow(
            title: "远程仓库",
            description: remotes.first?.url ?? "未配置",
            icon: .iconCloud
        ) {
            if let url = remotes.first?.url {
                MagicButton.simple {
                    url.toURL().openInBrowser()
                }
                .magicIcon(.iconSafari)
                .magicShapeVisibility(.onHover)
                .magicShape(.circle)
            }
        }
    }

    private func currentBranchRow(branch: GitBranch) -> some View {
        MagicSettingRow(
            title: "当前分支",
            description: branch.name,
            icon: .iconLog
        ) {
            EmptyView()
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
