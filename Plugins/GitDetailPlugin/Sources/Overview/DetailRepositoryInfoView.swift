import GitCoreKit
import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import ProjectRulesKit
import SwiftUI

struct DetailRepositoryInfoView: View, SuperLog {
    nonisolated static let emoji = "📁"
    nonisolated static let verbose = false

    let project: Project
    let remotes: [GitRemote]
    let branch: GitBranch?

    @State private var showSettings = false
    @State private var didCopyLocalPath = false
    @State private var localCopyFeedbackToken = UUID()
    @State private var copiedRemoteName: String?
    @State private var remoteCopyFeedbackToken = UUID()

    var body: some View {
        AppSettingSection(title: "仓库信息", titleAlignment: .leading) {
            VStack(spacing: 0) {
                localRepositoryRow

                if let branch {
                    Divider()
                        .padding(.vertical, 8)
                    currentBranchRow(branch: branch)
                }

                if !remotes.isEmpty {
                    Divider()
                        .padding(.vertical, 8)

                    ForEach(remotes, id: \.name) { remote in
                        if remote != remotes.first {
                            Divider()
                                .padding(.vertical, 8)
                        }
                        remoteRepositoryRow(for: remote)
                    }
                } else {
                    Divider()
                        .padding(.vertical, 8)
                    configRemoteRepositoryRow
                }
            }
        }
        .onChange(of: showSettings) { _, isPresented in
            if isPresented {
                NotificationCenter.default.post(name: .openRepositorySettings, object: nil)
                showSettings = false
            }
        }
    }

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
                if let httpsURL = RemoteRepositoryFormRules.remoteWebLink(for: remote.url)?.url {
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
