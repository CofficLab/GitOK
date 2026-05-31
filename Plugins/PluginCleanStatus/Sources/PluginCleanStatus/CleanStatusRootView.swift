import GitCoreKit
import GitOKPluginKit
import SwiftUI

struct CleanStatusRootView: View {
    let content: AnyView

    @Environment(\.gitOKProjectURL) private var projectURL
    @Environment(\.gitOKCleanStatusUpdateHandler) private var updateCleanStatus

    @State private var lastProjectURL: URL?

    var body: some View {
        content
            .onAppear(perform: checkCleanStatus)
            .onChange(of: projectURL) { _, _ in checkCleanStatus() }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusAppDidBecomeActive)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidChangeBranch)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidCommit)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidPush)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidPull)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidMerge)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidSync)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectDidAddFiles)) { _ in
                updateCleanStatus(false)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectGitIndexDidChange)) { _ in
                checkCleanStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginCleanStatusProjectGitHeadDidChange)) { _ in
                checkCleanStatus()
            }
    }

    private func checkCleanStatus() {
        guard let projectURL else {
            lastProjectURL = nil
            updateCleanStatus(true)
            return
        }

        lastProjectURL = projectURL

        Task {
            let isClean: Bool
            do {
                isClean = try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).statusEntries().isEmpty
                }.value
            } catch {
                isClean = true
            }

            guard lastProjectURL == projectURL else { return }
            updateCleanStatus(isClean)
        }
    }
}
