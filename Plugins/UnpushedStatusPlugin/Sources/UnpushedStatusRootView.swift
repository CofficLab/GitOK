import GitOKCoreKit
import GitCoreKit
import SwiftUI

struct UnpushedStatusRootView: View {
    let content: AnyView
    let projectURL: URL?
    let updateUnpushedCommits: GitOKUnpushedCommitsUpdateHandler
    let updateRemoteTracking: GitOKRemoteTrackingUpdateHandler

    @State private var unpushedTask: Task<Void, Never>?
    @State private var aheadBehindTask: Task<Void, Never>?

    var body: some View {
        content
            .onAppear {
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onChange(of: projectURL) {
                refreshUnpushedCount()
                refreshAheadBehind()
            }
            .onDisappear {
                unpushedTask?.cancel()
                aheadBehindTask?.cancel()
                unpushedTask = nil
                aheadBehindTask = nil
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
        unpushedTask?.cancel()

        guard let projectURL else {
            updateUnpushedCommits(0, [])
            return
        }

        unpushedTask = Task.detached(priority: .userInitiated) {
            do {
                let hashes = try GitRepositoryCLI(repositoryURL: projectURL).unpushedCommitHashes()
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    unpushedTask = nil
                    updateUnpushedCommits(hashes.count, hashes)
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    unpushedTask = nil
                    updateUnpushedCommits(0, [])
                }
            }
        }
    }

    private func refreshAheadBehind(markFetched: Bool = false) {
        aheadBehindTask?.cancel()

        guard let projectURL else {
            updateRemoteTracking(nil, nil)
            return
        }

        aheadBehindTask = Task.detached(priority: .userInitiated) {
            do {
                let state = try GitRepositoryCLI(repositoryURL: projectURL).aheadBehind()
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    aheadBehindTask = nil
                    updateRemoteTracking(
                        UnpushedStatusPresentation.remoteTrackingStatus(from: state),
                        markFetched ? .now : nil
                    )
                }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    aheadBehindTask = nil
                    updateRemoteTracking(.noUpstream, nil)
                }
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
