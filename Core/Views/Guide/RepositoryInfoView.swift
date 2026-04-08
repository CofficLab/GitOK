import Foundation
import LibGit2Swift
import MagicKit
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
    
    /// 本地仓库路径复制后的反馈状态
    @State private var didCopyLocalPath = false
    
    /// 本地复制反馈的令牌，用于避免快速连续点击导致状态提前恢复
    @State private var localCopyFeedbackToken = UUID()
    
    /// 当前显示“已复制”反馈的远程仓库名
    @State private var copiedRemoteName: String?
    
    /// 远程复制反馈的令牌
    @State private var remoteCopyFeedbackToken = UUID()

    var body: some View {
        AppSettingSection(title: "仓库信息", titleAlignment: .leading) {
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

                    ForEach(remotes, id: \.name) { remote in
                        if remote != remotes.first {
                            Divider()
                        }
                        remoteRepositoryRow(for: remote)
                    }
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
        AppSettingRow(
            title: "本地仓库",
            description: project.path,
            icon: .iconFolder
        ) {
            HStack(spacing: 8) {
                AppIconButton(systemImage: "folder", size: .regular) {
                    project.url.openFolder()
                }

                AppIconButton(
                    systemImage: didCopyLocalPath ? "checkmark" : "doc.on.doc",
                    tint: didCopyLocalPath ? .green : DesignTokens.Color.semantic.textSecondary.opacity(0.8),
                    size: .regular,
                    isActive: didCopyLocalPath
                ) {
                    copyLocalRepositoryPath()
                }
            }
        }
    }

    private func remoteRepositoryRow(for remote: GitRemote) -> some View {
        AppSettingRow(
            title: "远程仓库 (\(remote.name))",
            description: remote.url,
            icon: .iconCloud
        ) {
            HStack(spacing: 8) {
                if let httpsURL = convertToHTTPSURL(remote.url) {
                    AppIconButton(systemImage: .iconSafari, size: .regular) {
                        httpsURL.openInBrowser()
                    }
                }

                AppIconButton(
                    systemImage: copiedRemoteName == remote.name ? "checkmark" : "doc.on.doc",
                    tint: copiedRemoteName == remote.name ? .green : DesignTokens.Color.semantic.textSecondary.opacity(0.8),
                    size: .regular,
                    isActive: copiedRemoteName == remote.name
                ) {
                    copyRemoteRepositoryURL(remote)
                }
            }
        }
    }

    /// 配置远程仓库行（当没有远程仓库时显示）
    private var configRemoteRepositoryRow: some View {
        AppSettingRow(
            title: "远程仓库",
            description: "未配置",
            icon: .iconCloud
        ) {
            AppIconButton(systemImage: "gearshape", size: .regular) {
                showSettings = true
            }
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
    
    private func copyLocalRepositoryPath() {
        project.url.absoluteString.copy()
        
        let token = UUID()
        localCopyFeedbackToken = token
        
        withAnimation(.easeOut(duration: 0.12)) {
            didCopyLocalPath = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard localCopyFeedbackToken == token else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                didCopyLocalPath = false
            }
        }
    }
    
    private func copyRemoteRepositoryURL(_ remote: GitRemote) {
        remote.url.copy()
        
        let token = UUID()
        remoteCopyFeedbackToken = token
        
        withAnimation(.easeOut(duration: 0.12)) {
            copiedRemoteName = remote.name
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard remoteCopyFeedbackToken == token else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                copiedRemoteName = nil
            }
        }
    }

    private func currentBranchRow(branch: GitBranch) -> some View {
        AppSettingRow(
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
