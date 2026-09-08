import Foundation
import KitGit
import LumiUI
import ProviderGit
import ProviderProjects
import SwiftUI

private func loc(_ key: String) -> String {
    WorktreeCleanLocalization.string(key, bundle: .module)
}

/// 工作区干净状态下的信息视图：展示仓库信息与 Git 用户配置。
/// 由 `PluginWorktreeClean` 独立提供（从 CommitDetail 插件迁移）。
struct CleanStateInfoView: View {
    let project: Project
    @ObservedObject var viewModel: WorktreeCleanViewModel
    let git: any GitProviding
    let openUserSettings: (() -> Void)?

    @State private var remotes: [GitRemoteSummary] = []
    @State private var branchName: String?
    @State private var latestTag: String?
    @State private var commitCount: Int?
    @State private var firstCommitDate: Date?
    @State private var isLoadingInfo = true
    @State private var copiedRemoteNames: Set<String> = []

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

                    Divider().padding(.vertical, 8)
                    latestTagRow

                    Divider().padding(.vertical, 8)
                    commitCountRow

                    Divider().padding(.vertical, 8)
                    firstCommitRow

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

            GitUserPresetSectionView(
                presets: viewModel.userPresets,
                currentUserName: viewModel.currentUserName,
                currentUserEmail: viewModel.currentUserEmail,
                isLoadingUserConfiguration: viewModel.isLoadingUserConfiguration,
                isApplying: viewModel.isApplyingUserPreset,
                onApply: viewModel.applyUserPreset,
                onManage: openUserSettings
            )
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

    // MARK: - Latest Tag Row

    private var latestTagRow: some View {
        AppSettingRow(
            title: loc("Latest Tag"),
            description: latestTag ?? (isLoadingInfo ? "" : loc("No Tags")),
            icon: "tag"
        ) {
            if isLoadingInfo {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - Commit Count Row

    private var commitCountRow: some View {
        AppSettingRow(
            title: loc("Commits"),
            description: commitCount.map(String.init)
                ?? (isLoadingInfo ? "" : loc("Not Available")),
            icon: "number"
        ) {
            if isLoadingInfo {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - First Commit Row

    private var firstCommitRow: some View {
        AppSettingRow(
            title: loc("First Commit"),
            description: firstCommitDate.map { Self.dateFormatter.string(from: $0) }
                ?? (isLoadingInfo ? "" : loc("Not Available")),
            icon: "calendar"
        ) {
            if isLoadingInfo {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - Remote Repository Row

    private func remoteRepositoryRow(for remote: GitRemoteSummary) -> some View {
        let isCopied = copiedRemoteNames.contains(remote.name)
        return AppSettingRow(
            title: String(format: loc("Remote Repository (%@)"), remote.name),
            description: remote.url,
            icon: "cloud"
        ) {
            HStack(spacing: 8) {
                Group {
                    if isCopied {
                        AppIconButton(
                            systemImage: "checkmark",
                            size: .regular
                        ) {
                            copyRemoteURL(remote)
                        }
                        .foregroundStyle(.green)
                    } else {
                        AppIconButton(
                            systemImage: "doc.on.doc",
                            size: .regular
                        ) {
                            copyRemoteURL(remote)
                        }
                    }
                }
                if let httpsURL = git.webLink(for: remote.url) {
                    AppIconButton(systemImage: "safari", size: .regular) {
                        NSWorkspace.shared.open(httpsURL)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isCopied)
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
            description: viewModel.currentUserName.isEmpty ? loc("user.name not configured") : viewModel.currentUserName,
            icon: "person"
        ) {
            if viewModel.isLoadingUserConfiguration {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - User Email Row

    private var userEmailRow: some View {
        AppSettingRow(
            title: loc("Email"),
            description: viewModel.currentUserEmail.isEmpty ? loc("user.email not configured") : viewModel.currentUserEmail,
            icon: "envelope"
        ) {
            if viewModel.isLoadingUserConfiguration {
                ProgressView().controlSize(.small)
            }
        }
    }

    // MARK: - Load Data

    private func loadInfo() {
        isLoadingInfo = true

        Task.detached(priority: .utility) {
            // 加载远程仓库
            let loadedRemotes = git.listRemotes(in: project.url)

            // 加载当前分支
            let loadedBranchName = git.currentBranch(in: project.url)

            // 加载当前 HEAD 可追溯到的最近 tag
            let loadedLatestTag = git.latestTag(in: project.url)

            // 加载提交总数（`git rev-list --count HEAD`；空仓库 / 失败时为 nil）
            let loadedCommitCount = try? git.countCommits(in: project.url)

            // 加载第一次提交时间（空仓库 / 失败时为 nil）
            let loadedFirstCommitDate = git.firstCommitDate(in: project.url)

            await MainActor.run {
                remotes = loadedRemotes
                branchName = loadedBranchName
                latestTag = loadedLatestTag
                commitCount = loadedCommitCount
                firstCommitDate = loadedFirstCommitDate
                isLoadingInfo = false
            }
        }
    }

    // MARK: - Helpers

    private func copyText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func copyRemoteURL(_ remote: GitRemoteSummary) {
        copyText(remote.url)
        copiedRemoteNames.insert(remote.name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedRemoteNames.remove(remote.name)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
