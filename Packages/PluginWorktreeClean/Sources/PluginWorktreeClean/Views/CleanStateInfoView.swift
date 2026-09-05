import Foundation
import KitGit
import LumiUI
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// 工作区干净状态下的信息视图：展示仓库信息与 Git 用户配置。
/// 由 `PluginWorktreeClean` 独立提供（从 CommitDetail 插件迁移）。
struct CleanStateInfoView: View {
    let project: Project

    @State private var remotes: [GitRemoteSummary] = []
    @State private var branchName: String?
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var isLoadingInfo = true

    var body: some View {
        VStack(spacing: 16) {
            // 仓库信息
            AppSettingSection(title: loc("Repository Info"), titleAlignment: .leading) {
                VStack(spacing: 0) {
                    localRepositoryRow

                    if let branchName {
                        Divider().padding(.vertical, 8)
                        currentBranchRow(branchName: branchName)
                    }

                    if !remotes.isEmpty {
                        Divider().padding(.vertical, 8)
                        ForEach(Array(remotes.enumerated()), id: \.element.name) { index, remote in
                            if index > 0 {
                                Divider().padding(.vertical, 8)
                            }
                            remoteRepositoryRow(for: remote)
                        }
                    } else {
                        Divider().padding(.vertical, 8)
                        noRemoteRow
                    }
                }
            }

            // Git 用户配置
            AppSettingSection(title: loc("Git User Configuration"), titleAlignment: .leading) {
                VStack(spacing: 0) {
                    userNameRow
                    Divider().padding(.vertical, 8)
                    userEmailRow
                }
            }
        }
        .onAppear(perform: loadInfo)
    }

    // MARK: - Local Repository Row

    private var localRepositoryRow: some View {
        AppSettingRow(
            title: loc("Local Repository"),
            description: project.url.path,
            icon: "folder"
        ) {
            HStack(spacing: 8) {
                AppIconButton(systemImage: "folder", size: .regular) {
                    NSWorkspace.shared.activateFileViewerSelecting([project.url])
                }
            }
        }
    }

    // MARK: - Current Branch Row

    private func currentBranchRow(branchName: String) -> some View {
        AppSettingRow(
            title: loc("Current Branch"),
            description: branchName,
            icon: "arrow.triangle.branch"
        ) {
            EmptyView()
        }
    }

    // MARK: - Remote Repository Row

    private func remoteRepositoryRow(for remote: GitRemoteSummary) -> some View {
        AppSettingRow(
            title: String(format: loc("Remote Repository (%@)"), remote.name),
            description: remote.url,
            icon: "cloud"
        ) {
            HStack(spacing: 8) {
                if let httpsURL = GitRemoteOperation.webLink(for: remote.url) {
                    AppIconButton(systemImage: "safari", size: .regular) {
                        NSWorkspace.shared.open(httpsURL)
                    }
                }
            }
        }
    }

    // MARK: - No Remote Row

    private var noRemoteRow: some View {
        AppSettingRow(
            title: loc("Remote Repository"),
            description: loc("Not Configured"),
            icon: "cloud"
        ) {
            EmptyView()
        }
    }

    // MARK: - User Name Row

    private var userNameRow: some View {
        AppSettingRow(
            title: loc("User Name"),
            description: userName.isEmpty ? loc("user.name not configured") : userName,
            icon: "person"
        ) {
            if isLoadingInfo {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - User Email Row

    private var userEmailRow: some View {
        AppSettingRow(
            title: loc("Email"),
            description: userEmail.isEmpty ? loc("user.email not configured") : userEmail,
            icon: "envelope"
        ) {
            if isLoadingInfo {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - Load Data

    private func loadInfo() {
        isLoadingInfo = true

        Task.detached(priority: .utility) {
            // 加载远程仓库
            let loadedRemotes = GitRemoteOperation.listRemotes(in: project.url)

            // 加载当前分支
            let loadedBranchName = GitRefReader.currentBranch(in: project.url)

            // 加载用户配置
            let config = GitConfigReader.user(in: project.url)

            await MainActor.run {
                remotes = loadedRemotes
                branchName = loadedBranchName
                userName = config.name ?? ""
                userEmail = config.email ?? ""
                isLoadingInfo = false
            }
        }
    }

    // MARK: - Helpers
}
