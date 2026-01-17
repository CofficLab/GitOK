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

    /// 是否显示设置界面
    @State private var showSettings = false

    var body: some View {
        MagicSettingSection(title: "仓库信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                // 本地仓库位置
                localRepositoryRow
                
                if let branch = branch {
                    Divider()

                    // 当前分支
                    currentBranchRow(branch: branch)
                }

                // 远程仓库位置
                if !remotes.isEmpty {
                    Divider()

                    remoteRepositoryRow
                } else {
                    // 没有远程仓库时显示配置入口
                    Divider()

                    configRemoteRepositoryRow
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingView(defaultTab: .repository)
                .onAppear {
                    if Self.verbose {
                        os_log("\(Self.t)Opening repository settings for project: \(project.title)")
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
            HStack(spacing: 8) {
                MagicButton.simple {
                    project.url.openFolder()
                }
                .magicIcon(.iconFinder)
                .magicShapeVisibility(.onHover)
                .magicShape(.circle)

                MagicButton.simple {
                    project.url.absoluteString.copy()
                }
                .magicIcon(.iconCopy)
                .magicShapeVisibility(.onHover)
                .magicShape(.circle)
            }
        }
    }

    private var remoteRepositoryRow: some View {
        MagicSettingRow(
            title: "远程仓库",
            description: remotes.first?.url ?? "未配置",
            icon: .iconCloud
        ) {
            if let url = remotes.first?.url {
                HStack(spacing: 8) {
                    if let httpsURL = convertToHTTPSURL(url) {
                        MagicButton.simple {
                            httpsURL.openInBrowser()
                        }
                        .magicIcon(.iconSafari)
                        .magicShapeVisibility(.onHover)
                        .magicShape(.circle)
                    }

                    MagicButton.simple {
                        url.copy()
                    }
                    .magicIcon(.iconCopy)
                    .magicShapeVisibility(.onHover)
                    .magicShape(.circle)
                }
            }
        }
    }

    /// 配置远程仓库行（当没有远程仓库时显示）
    private var configRemoteRepositoryRow: some View {
        MagicSettingRow(
            title: "远程仓库",
            description: "未配置",
            icon: .iconCloud
        ) {
            MagicButton.simple {
                showSettings = true
            }
            .magicIcon(.iconSettings)
            .magicShape(.circle)
            .magicShapeVisibility(.onHover)
        }
    }

    // MARK: - Helper Methods

    /// 将 Git URL 转换为 HTTPS URL
    /// - Parameter gitURL: Git URL（可能是 SSH 或 HTTPS 格式）
    /// - Returns: 可在浏览器中打开的 HTTPS URL，如果无法转换则返回 nil
    private func convertToHTTPSURL(_ gitURL: String) -> URL? {
        var formatted = gitURL

        // 处理 SSH 格式：git@github.com:user/repo.git
        if formatted.hasPrefix("git@") {
            formatted = formatted.replacingOccurrences(of: ":", with: "/")
            formatted = formatted.replacingOccurrences(of: "git@", with: "https://")
        }
        // 处理 SSH 格式：ssh://git@github.com/user/repo.git
        else if formatted.hasPrefix("ssh://") {
            formatted = formatted.replacingOccurrences(of: "ssh://git@", with: "https://")
        }
        // 处理 git:// 协议
        else if formatted.hasPrefix("git://") {
            formatted = formatted.replacingOccurrences(of: "git://", with: "https://")
        }

        // 如果已经是 HTTPS 格式，直接使用
        return URL(string: formatted)
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
