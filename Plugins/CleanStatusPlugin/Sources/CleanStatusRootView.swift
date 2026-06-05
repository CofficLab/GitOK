import GitCoreKit
import GitOKCoreKit
import SwiftUI

struct CleanStatusRootView: View {
    let content: AnyView
    let projectURL: URL?
    let updateCleanStatus: GitOKCleanStatusUpdateHandler

    @State private var lastProjectURL: URL?
    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        content
            .onAppear(perform: checkCleanStatus)
            .onChange(of: projectURL) {
                checkCleanStatus()
            }
            .onDisappear {
                checkTask?.cancel()
                checkTask = nil
            }
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
        checkTask?.cancel()

        guard let projectURL else {
            lastProjectURL = nil
            updateCleanStatus(true)
            return
        }

        lastProjectURL = projectURL

        checkTask = Task.detached(priority: .userInitiated) {
            do {
                let isClean = try GitRepositoryCLI(repositoryURL: projectURL).statusEntries().isEmpty
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    guard lastProjectURL == projectURL else { return }
                    checkTask = nil
                    updateCleanStatus(isClean)
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    guard lastProjectURL == projectURL else { return }
                    checkTask = nil
                    updateCleanStatus(true)
                }
            }
        }
    }
}
