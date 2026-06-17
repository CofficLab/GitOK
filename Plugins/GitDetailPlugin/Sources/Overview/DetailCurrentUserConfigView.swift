import GitCoreKit
import GitOKAppCore
import GitOKSupportKit
import GitOKUI
import OSLog
import SwiftUI

struct DetailCurrentUserConfigView: View, SuperLog {
    nonisolated static let emoji = "👤"
    nonisolated static let verbose = false

    let project: Project

    @State private var userName = ""
    @State private var userEmail = ""
    @State private var isLoading = true

    var body: some View {
        AppSettingSection(title: "Git 用户配置", titleAlignment: .leading) {
            VStack(spacing: 0) {
                userNameRow
                Divider()
                    .padding(.vertical, 8)
                userEmailRow
            }
        }
        .onAppear(perform: loadUserInfo)
        .onDetailGitUserConfigUpdated(perform: loadUserInfo)
    }

    private var userNameRow: some View {
        AppSettingRow(
            title: "用户名",
            description: userName.isEmpty ? "未配置 user.name" : userName,
            icon: .iconUser
        ) {
            if isLoading {
                AppLoadingOverlay(size: .small)
            }
        }
    }

    private var userEmailRow: some View {
        AppSettingRow(
            title: "邮箱",
            description: userEmail.isEmpty ? "未配置 user.email" : userEmail,
            icon: .iconMail
        ) {
            if isLoading {
                AppLoadingOverlay(size: .small)
            }
        }
    }

    private func loadUserInfo() {
        let repositoryURL = project.url
        isLoading = true

        Task.detached(priority: .utility) {
            do {
                let cli = GitRepositoryCLI(repositoryURL: repositoryURL)
                let loadedName = try cli.configValue(key: "user.name")
                let loadedEmail = try cli.configValue(key: "user.email")

                await MainActor.run {
                    userName = loadedName
                    userEmail = loadedEmail
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    userName = ""
                    userEmail = ""
                    isLoading = false
                    if Self.verbose {
                        os_log(.error, "\(Self.t)Failed to load Git user config")
                    }
                }
            }
        }
    }
}

private extension View {
    func onDetailGitUserConfigUpdated(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .didUpdateGitUserConfig)) { _ in
            action()
        }
    }
}
