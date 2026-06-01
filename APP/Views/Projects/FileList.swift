import GitOKCoreFeatures
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import SwiftUI

/// Git 文件变更列表入口。列表实现逻辑由 CoreKit 的 FileListHostView 提供。
struct FileList: View, SuperLog {
    nonisolated static let emoji = "📁"
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var projectChangeToken = 0
    @State private var commitChangeToken = 0
    @State private var projectDidCommitToken = 0
    @State private var projectDidAddFilesToken = 0
    @State private var projectDidAddFilesPath: String?
    @State private var gitDirectoryChangeToken = 0
    @State private var gitDirectoryEventProjectPath: String?
    @State private var appWillBecomeActiveToken = 0

    var body: some View {
        FileListHostView(
            project: vm.project,
            selectedCommit: data.commit,
            projectURL: \.url,
            projectPath: \.path,
            commitHash: \.hash,
            filePath: \.file,
            fileChangeType: \.changeType,
            statusPath: \.path,
            statusIndexStatus: { $0.indexStatus },
            statusWorkTreeStatus: { $0.workTreeStatus },
            scrollTarget: vm.file,
            syncSelection: { vm.setFile($0) },
            loadCommitFiles: { project, hash in
                try await project.changedFilesDetail(in: hash)
            },
            loadWorktreeFiles: { project in
                try await project.untrackedFiles()
            },
            loadStatusEntries: { project in
                try project.statusEntries()
            },
            addFiles: { project, paths in
                try project.addFiles(paths)
            },
            unstageFiles: { project, paths in
                try project.unstageFiles(paths)
            },
            discardFileChanges: { project, path in
                try project.discardFileChanges(path)
            },
            discardAllChanges: { project in
                try project.discardAllChanges()
            },
            mapRefreshError: mapRefreshError,
            eventHandler: handleEvent(_:),
            projectChangeToken: projectChangeToken,
            commitChangeToken: commitChangeToken,
            projectDidCommitToken: projectDidCommitToken,
            projectDidAddFilesToken: projectDidAddFilesToken,
            projectDidAddFilesPath: projectDidAddFilesPath,
            gitDirectoryChangeToken: gitDirectoryChangeToken,
            gitDirectoryEventProjectPath: gitDirectoryEventProjectPath,
            appWillBecomeActiveToken: appWillBecomeActiveToken
        )
        .onChange(of: vm.project) {
            projectChangeToken += 1
        }
        .onChange(of: data.commit) {
            commitChangeToken += 1
        }
        .onProjectDidCommit { _ in
            projectDidCommitToken += 1
        }
        .onProjectDidAddFiles { eventInfo in
            projectDidAddFilesPath = eventInfo.project.path
            projectDidAddFilesToken += 1
        }
        .onProjectGitIndexDidChange(perform: onGitDirectoryDidChange)
        .onProjectGitHeadDidChange(perform: onGitDirectoryDidChange)
        .onApplicationWillBecomeActive {
            appWillBecomeActiveToken += 1
        }
    }
}

private extension FileList {
    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        gitDirectoryEventProjectPath = eventInfo.project.path
        gitDirectoryChangeToken += 1
    }

    func mapRefreshError(_ error: Error) -> String {
        GitDetailError.from(error, context: FileListRules.refreshFileListErrorContext).localizedDescription
    }

    func handleEvent(_ event: FileListHostEvent) {
        switch event {
        case let .showInfoMessage(message):
            GitDetailAlertRules.performInfo(message) {
                alert_info($0)
            }
        case let .showError(error):
            GitDetailAlertRules.performError(error) {
                alert_error($0)
            }
        case let .log(event):
            logEvent(event)
        }
    }

    func logEvent(_ event: FileListHostLogEvent) {
        switch event {
        case let .refreshSkipped(reason):
            logVerbose(FileListRules.refreshSkippedLogMessage(reason: reason))
        case let .refreshStarted(reason):
            logVerbose(FileListRules.refreshStartedLogMessage(reason: reason))
        case .commitChangedDuringRefresh:
            logVerbose(FileListRules.commitChangedDuringRefreshLogMessage())
        case let .refreshCancelled(reason):
            logVerbose(FileListRules.refreshCancelledLogMessage(reason: reason))
        case let .refreshFailure(message):
            logError(FileListRules.refreshFailureLogMessage(errorDescription: message))
        case let .fileOperationFailure(failureLogMessage, error):
            logError(FileListRules.fileOperationFailureLogMessage(
                failureLogMessage: failureLogMessage,
                errorDescription: error.localizedDescription
            ))
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
