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
                try project.getUnPulledCount()
            },
            pull: { project in
                try project.pull()
            },
            push: { project in
                try project.push()
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

    func currentRemoteAccess() -> CommitRemoteSyncRules.RemoteAccess {
        CommitRemoteSyncRules.projectRemoteAccess(
            project: vm.project,
            loadRemotes: { try $0.remoteList() },
            name: \.name,
            url: \.url,
            fetchURL: \.fetchURL,
            pushURL: \.pushURL
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
        case let .syncStatusUpdated(unpushedCount, unpulledCount):
            logVerbose(CommitRemoteSyncRules.syncStatusUpdatedLogMessage(
                unpushedCount: unpushedCount,
                unpulledCount: unpulledCount
            ))
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
