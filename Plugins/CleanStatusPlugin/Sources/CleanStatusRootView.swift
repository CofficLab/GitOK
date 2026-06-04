import GitCoreKit
import GitOKCoreKit
import SwiftUI

struct CleanStatusRootView: View {
    let content: AnyView
    let projectURL: URL?
    let updateCleanStatus: GitOKCleanStatusUpdateHandler

    @State private var lastProjectURL: URL?

    var body: some View {
        content
            .onAppear(perform: checkCleanStatus)
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

        Task.detached(priority: .userInitiated) {
            do {
                let isClean = try GitRepositoryCLI(repositoryURL: projectURL).statusEntries().isEmpty
                await MainActor.run {
                    guard lastProjectURL == projectURL else { return }
                    updateCleanStatus(isClean)
                }
            } catch {
                await MainActor.run {
                    guard lastProjectURL == projectURL else { return }
                    updateCleanStatus(true)
                }
            }
        }
    }
}
