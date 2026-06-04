import AppKit
import GitCoreKit
import GitOKCoreFeatures
import MagicAlert
import GitOKSupportKit
import OSLog
import ProjectRulesKit
import SwiftUI

/// 当前工作状态入口。实现逻辑由 CoreKit 的 WorkingStateHostView 提供。
struct WorkingStateView: View, SuperLog {
    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @Binding var isRefreshing: Bool

    @State private var projectChangeToken = 0
    @State private var projectDidCommitToken = 0
    @State private var projectDidPushToken = 0
    @State private var projectDidPullToken = 0
    @State private var gitDirectoryChangeToken = 0
    @State private var gitDirectoryEventProjectPath: String?
    @State private var gitDirectoryDidHeadChange = false
    @State private var appDidBecomeActiveToken = 0

    nonisolated static let verbose = false
    nonisolated static let emoji = "🌳"

    init(isRefreshing: Binding<Bool> = .constant(false)) {
        _isRefreshing = isRefreshing
    }

    var body: some View {
        WorkingStateHostView(
            project: vm.project,
            selectedCommit: data.commit,
            isRefreshing: $isRefreshing,
            externalActivityStatus: data.activityStatus,
            setSelectedCommit: { data.commit = $0 },
            setActivityStatus: { data.activityStatus = $0 },
            updateCleanState: { vm.updateIsClean($0) },
            projectPath: \.path,
            loadChangedFileCount: { project in
                try await project.untrackedFiles().count
            },
            loadUnpushedCommits: { project in
                try await project.getUnPushedCommits()
            },
            loadUnpulledCount: { project in
                try await project.getUnPulledCountAsync()
            },
            loadRemoteTrackingStatus: { project in
                let status = try await project.aheadBehindAsync()
                return GitOKRemoteTrackingStatus(
                    ahead: status.ahead,
                    behind: status.behind,
                    hasUpstream: status.hasUpstream
                )
            },
            updateRemoteTrackingStatus: { status, fetchedAt in
                vm.updateRemoteTracking(status, fetchedAt: fetchedAt)
            },
            fetch: { project in
                try await project.fetchAsync()
            },
            pull: { project in
                try await project.pullAsync()
            },
            push: { project in
                try await project.pushAsync()
            },
            loadConflictState: { project in
                try await loadConflictState(for: project)
            },
            stageConflictFile: { project, path in
                try await project.addFilesAsync([path])
            },
            useConflictFileVersion: { project, path, version in
                try await project.checkoutMergeFileVersionAsync(path: path, version: version)
            },
            continueMerge: { project in
                let branchName = (try? await project.getCurrentMergeBranchNameAsync()) ?? "MERGE_HEAD"
                try await project.continueMerge(branchName: branchName)
            },
            abortMerge: { project in
                try await project.abortMerge()
            },
            openConflictFile: { project, path in
                openConflictFile(project: project, path: path)
            },
            revealConflictFile: { project, path in
                revealConflictFile(project: project, path: path)
            },
            pushErrorClassification: pushErrorClassification,
            runNetworkFallback: runNetworkFallback,
            currentRemoteAccess: currentRemoteAccess,
            showNetworkFallbackSelection: showNetworkFallbackSelection,
            eventHandler: handleEvent(_:),
            projectChangeToken: projectChangeToken,
            projectDidCommitToken: projectDidCommitToken,
            projectDidPushToken: projectDidPushToken,
            projectDidPullToken: projectDidPullToken,
            gitDirectoryChangeToken: gitDirectoryChangeToken,
            gitDirectoryEventProjectPath: gitDirectoryEventProjectPath,
            gitDirectoryDidHeadChange: gitDirectoryDidHeadChange,
            appDidBecomeActiveToken: appDidBecomeActiveToken
        ) { remoteURL, errorMessage, onDismiss in
            CloneSSHAuthenticationHelpView(
                remoteURL: remoteURL,
                errorMessage: errorMessage,
                onRetry: onDismiss
            )
        }
        .onChange(of: vm.project) {
            projectChangeToken += 1
        }
        .onProjectDidCommit { _ in
            projectDidCommitToken += 1
        }
        .onProjectDidPush { _ in
            projectDidPushToken += 1
        }
        .onProjectDidPull { _ in
            projectDidPullToken += 1
        }
        .onProjectGitIndexDidChange(perform: onGitDirectoryDidChange)
        .onProjectGitHeadDidChange(perform: onGitDirectoryDidChange)
        .onNotification(.appDidBecomeActive, perform: { _ in
            appDidBecomeActiveToken += 1
        })
    }
}

private extension WorkingStateView {
    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        gitDirectoryEventProjectPath = eventInfo.project.path
        gitDirectoryDidHeadChange = eventInfo.additionalInfo?[CommitRemoteSyncRules.gitHeadChangedEventInfoKey] as? Bool == true
        gitDirectoryChangeToken += 1
    }

    func showNetworkFallbackSelection(
        _ text: CommitRemoteSyncRules.NetworkFallbackAlertText
    ) -> CommitRemoteSyncRules.NetworkFallbackSelection {
        let alert = NSAlert()
        alert.messageText = text.title
        alert.informativeText = text.message
        alert.alertStyle = .warning
        alert.addButton(withTitle: text.retryButtonTitle)
        alert.addButton(withTitle: text.toggleSSHPushButtonTitle)
        alert.addButton(withTitle: text.cancelButtonTitle)

        return CommitRemoteSyncRules.networkFallbackSelection(
            response: alert.runModal(),
            firstButton: .alertFirstButtonReturn,
            secondButton: .alertSecondButtonReturn
        )
    }

    func currentRemoteAccess() async -> CommitRemoteSyncRules.RemoteAccess {
        guard let project = vm.project,
              let remotes = try? await project.remoteListAsync() else {
            return .empty
        }

        return CommitRemoteSyncRules.remoteAccess(
            from: CommitRemoteSyncRules.remoteURLs(
                from: remotes,
                name: \.name,
                url: \.url,
                fetchURL: \.fetchURL,
                pushURL: \.pushURL
            )
        )
    }

    func runNetworkFallback(
        _ project: Project,
        projectPath: String,
        setStatus: @escaping (String?) -> Void
    ) async -> Bool {
        await project.runSystemGitPushFallback(
            setStatus: { statusText in
                await MainActor.run {
                    setStatus(statusText)
                }
            },
            onFailure: { error in
                await MainActor.run {
                    handleEvent(.log(.systemGitPushFailure(error)))
                }
            }
        )
    }

    nonisolated func pushErrorClassification(_ error: Error) -> CommitRemoteSyncRules.PushErrorClassification {
        CommitRemoteSyncRules.pushErrorClassification(error: error)
    }
}

private extension WorkingStateView {
    func loadConflictState(for project: Project) async throws -> WorkingStateConflictState {
        let isMerging = try await project.isMerging()
        let unresolvedPaths = Set(try await project.getMergeConflictFiles())
        guard isMerging || unresolvedPaths.isEmpty == false else {
            return .inactive
        }

        let statusEntries = try await project.lightweightStatusEntriesAsync()
        let mergeBranchName = try? await project.getCurrentMergeBranchNameAsync()
        let flattenedMergeBranchName = mergeBranchName.flatMap { $0 }

        return WorkingStateConflictState(
            isMerging: true,
            mergeBranchName: flattenedMergeBranchName,
            files: WorkingStateConflictRules.mergeFiles(
                unresolvedPaths: unresolvedPaths,
                statusEntries: statusEntries
            )
        )
    }

    func openConflictFile(project: Project, path: String) {
        guard let url = conflictFileURL(project: project, path: path) else { return }
        NSWorkspace.shared.open(url)
    }

    func revealConflictFile(project: Project, path: String) {
        guard let url = conflictFileURL(project: project, path: path) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func conflictFileURL(project: Project, path: String) -> URL? {
        let repoURL = project.url.standardizedFileURL
        let fileURL = URL(fileURLWithPath: path, relativeTo: repoURL).standardizedFileURL
        guard fileURL.path == repoURL.path || fileURL.path.hasPrefix(repoURL.path + "/") else {
            return nil
        }
        return fileURL
    }

    func handleEvent(_ event: WorkingStateHostEvent) {
        switch event {
        case let .showError(error):
            CommitAlertRules.performError(error) {
                alert_error($0)
            }
        case let .log(event):
            logEvent(event)
        }
    }

    func logEvent(_ event: WorkingStateHostLogEvent) {
        switch event {
        case .missingProject:
            logVerbose(CommitRemoteSyncRules.missingProjectLogMessage())
        case let .changedFileCountFailure(error):
            logError(CommitRemoteSyncRules.changedFileCountFailureLogMessage(errorDescription: String(describing: error)))
        case let .syncStatusLoad(projectPath):
            logVerbose(CommitRemoteSyncRules.syncStatusLoadLogMessage(projectPath: projectPath))
        case let .unpushedCountFailure(error):
            logError(CommitRemoteSyncRules.unpushedCountFailureLogMessage(errorDescription: String(describing: error)))
        case let .unpulledCountFailure(error):
            logError(CommitRemoteSyncRules.unpulledCountFailureLogMessage(errorDescription: String(describing: error)))
        case let .remoteTrackingFailure(error):
            logError("❌ Failed to load remote tracking status: \(String(describing: error))")
        case let .syncStatusUpdated(unpushedCount, unpulledCount):
            logVerbose(CommitRemoteSyncRules.syncStatusUpdatedLogMessage(
                unpushedCount: unpushedCount,
                unpulledCount: unpulledCount
            ))
        case let .fetchStart(projectPath):
            logVerbose("<\(projectPath)>Performing git fetch")
        case .fetchSuccess:
            logAlways("✅ Git fetch succeeded")
        case let .fetchFailure(error):
            logError("❌ Git fetch failed: \(String(describing: error))")
        case let .pullStart(projectPath):
            logVerbose(CommitRemoteSyncRules.pullOperationLogMessage(projectPath: projectPath))
        case let .pushStart(projectPath):
            logVerbose(CommitRemoteSyncRules.pushOperationLogMessage(projectPath: projectPath))
        case .pullSuccess:
            logAlways(CommitRemoteSyncRules.pullSuccessLogMessage())
        case let .pullFailure(error):
            logError(CommitRemoteSyncRules.pullFailureLogMessage(errorDescription: String(describing: error)))
        case let .pushSuccess(retryAttempt):
            logAlways(CommitRemoteSyncRules.pushSuccessLogMessage(retryAttempt: retryAttempt))
        case .pushRetryStart:
            logVerbose(CommitRemoteSyncRules.pushRetryStartLogMessage())
        case let .pushRetryFailure(retryAttempt):
            logVerbose(CommitRemoteSyncRules.pushRetryFailureLogMessage(retryAttempt: retryAttempt))
        case .timerFired:
            logVerbose(CommitRemoteSyncRules.remoteStatusTimerFiredLogMessage())
        case let .timerStarted(interval):
            logVerbose(CommitRemoteSyncRules.remoteStatusTimerStartedLogMessage(interval: interval))
        case .timerStopped:
            logVerbose(CommitRemoteSyncRules.remoteStatusTimerStoppedLogMessage())
        case let .systemGitPushFailure(error):
            logVerbose(CommitRemoteSyncRules.systemGitPushFailureLogMessage(errorDescription: String(describing: error)))
        }
    }

    func logVerbose(_ message: String) {
        if Self.verbose {
            logAlways(message)
        }
    }

    func logAlways(_ message: String) {
        os_log("\(self.t)\(message)")
    }

    func logError(_ message: String) {
        os_log(.error, "\(self.t)\(message)")
    }
}
