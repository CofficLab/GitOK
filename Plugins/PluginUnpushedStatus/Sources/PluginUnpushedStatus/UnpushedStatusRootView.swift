import GitOKCoreKit
import SwiftUI

struct UnpushedStatusRootView: View {
    let content: AnyView
    let projectURL: URL?
    let updateUnpushedCommits: GitOKUnpushedCommitsUpdateHandler
    let updateRemoteTracking: GitOKRemoteTrackingUpdateHandler

    var body: some View {
        content
            .onAppear {
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusAppDidBecomeActive)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectDidChangeBranch)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectDidCommit)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectDidFetch)) { _ in
                refreshAheadBehind(markFetched: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectDidPush)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectDidPull)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectGitHeadDidChange)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onReceive(NotificationCenter.default.publisher(for: .pluginUnpushedStatusProjectGitRefsDidChange)) { _ in
                refreshUnpushedCount()
                refreshAheadBehind()
            }
    }

    private func refreshUnpushedCount() {
        guard let projectURL else {
            updateUnpushedCommits(0, [])
            return
        }

        Task(priority: .userInitiated) {
            do {
                let hashes = try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).unpushedCommitHashes()
                }.value
                updateUnpushedCommits(hashes.count, hashes)
            } catch {
                updateUnpushedCommits(0, [])
            }
        }
    }

    private func refreshAheadBehind(markFetched: Bool = false) {
        guard let projectURL else {
            updateRemoteTracking(nil, nil)
            return
        }

        Task(priority: .userInitiated) {
            do {
                let state = try await Task.detached(priority: .userInitiated) {
                    try GitRepositoryCLI(repositoryURL: projectURL).aheadBehind()
                }.value
                updateRemoteTracking(
                    UnpushedStatusPresentation.remoteTrackingStatus(from: state),
                    markFetched ? .now : nil
                )
            } catch {
                updateRemoteTracking(.noUpstream, nil)
            }
        }
    }
}

enum UnpushedStatusPresentation {
    static func remoteTrackingStatus(from state: GitAheadBehind) -> GitOKRemoteTrackingStatus {
        GitOKRemoteTrackingStatus(
            ahead: state.ahead,
            behind: state.behind,
            hasUpstream: state.hasUpstream
        )
    }
}

private extension GitOKRemoteTrackingStatus {
    static let noUpstream = GitOKRemoteTrackingStatus(ahead: 0, behind: 0, hasUpstream: false)
}
