import GitCoreKit
import LibGit2Swift
import MagicAlert
import MagicKit
import OSLog
import GitOKCoreFeatures
import SwiftUI

/// 提交记录行入口。行状态和操作逻辑由 CoreKit 的 CommitRowHostView 提供。
struct CommitRow: View, SuperLog {
    nonisolated static let emoji = "📝"
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    let commit: GitCommit
    let isFirstCommit: Bool
    let commitIndex: Int
    let graphRow: CommitGraphPresentationRules.Row?
    let graphLaneCount: Int

    @State private var appWillBecomeActiveToken = 0
    @State private var projectDidCommitToken = 0
    @State private var refsDidChangeToken = 0
    @State private var refsDidChangeProjectPath: String?

    var body: some View {
        CommitRowHostView(
            project: vm.project,
            commit: commit,
            isFirstCommit: isFirstCommit,
            commitIndex: commitIndex,
            graphRow: graphRow,
            graphLaneCount: graphLaneCount,
            currentCommitID: data.commit?.hash,
            isCommitUnpushed: { vm.isCommitUnpushed($0) },
            selectCommit: { data.setCommit($0) },
            commitHash: \.hash,
            commitMessage: \.message,
            commitAuthor: \.author,
            commitAllAuthors: \.allAuthors,
            commitRelativeTime: { $0.date.smartRelativeTime },
            commitFullDateTime: { $0.date.fullDateTime },
            commitParentHashes: \.parentHashes,
            commitTagCount: { $0.tags.count },
            projectPath: \.path,
            pushProject: { project in
                try await Task.detached(priority: .userInitiated) {
                    try project.push()
                }.value
            },
            undoCommit: { project, commit in
                try await Task.detached(priority: .userInitiated) {
                    try project.undoCommit(commit)
                }.value
            },
            revertCommit: { project, commit in
                try await Task.detached(priority: .userInitiated) {
                    try project.revertCommit(commit)
                }.value
            },
            resetToCommit: { project, commit, mode in
                try await Task.detached(priority: .userInitiated) {
                    try project.reset(to: commit, mode: mode)
                }.value
            },
            squashLastCommits: { project, validation in
                try await Task.detached(priority: .userInitiated) {
                    try project.squashLastCommits(count: validation.count, message: validation.message)
                }.value
            },
            loadTags: { project, hash in
                try await Task.detached(priority: .userInitiated) {
                    try project.getTags(commit: hash)
                }.value
            },
            createLightweightTag: { project, tagName, commitHash in
                try await Task.detached(priority: .userInitiated) {
                    try project.createLightweightTag(named: tagName, commitHash: commitHash)
                }.value
            },
            createAnnotatedTag: { project, tagName, commitHash, message in
                try await Task.detached(priority: .userInitiated) {
                    try project.createAnnotatedTag(named: tagName, commitHash: commitHash, message: message)
                }.value
            },
            deleteLocalTag: { project, tagName in
                try await Task.detached(priority: .userInitiated) {
                    try project.deleteLocalTag(named: tagName)
                }.value
            },
            pushTagOperation: { project, tagName in
                try await Task.detached(priority: .userInitiated) {
                    try project.pushTag(named: tagName)
                }.value
            },
            deleteRemoteTag: { project, tagName in
                try await Task.detached(priority: .userInitiated) {
                    try project.deleteRemoteTag(named: tagName)
                }.value
            },
            eventHandler: handleEvent(_:),
            appWillBecomeActiveToken: appWillBecomeActiveToken,
            projectDidCommitToken: projectDidCommitToken,
            refsDidChangeToken: refsDidChangeToken,
            refsDidChangeProjectPath: refsDidChangeProjectPath
        )
        .onNotification(.appWillBecomeActive, perform: { _ in
            appWillBecomeActiveToken += 1
        })
        .onProjectDidCommit { _ in
            projectDidCommitToken += 1
        }
        .onProjectGitRefsDidChange { eventInfo in
            refsDidChangeProjectPath = eventInfo.project.path
            refsDidChangeToken += 1
        }
    }
}

private extension CommitRow {
    func handleEvent(_ event: CommitRowHostEvent) {
        switch event {
        case let .showErrorMessage(message):
            CommitAlertRules.performMessage(message) {
                alert_error($0)
            }
        case let .showInfoMessage(message):
            CommitAlertRules.performInfo(message) {
                alert_info($0)
            }
        case let .showError(error):
            CommitAlertRules.performError(error) {
                alert_error($0)
            }
        case let .log(event):
            logEvent(event)
        }
    }

    func logEvent(_ event: CommitRowHostLogEvent) {
        switch event {
        case let .selection(hash, message):
            logVerbose(CommitRowAppearanceRules.commitSelectionLogMessage(hash: hash, message: message))
        case let .pushStart(hash):
            logVerbose(CommitRowAppearanceRules.pushStartLogMessage(hash: hash))
        case let .pushSuccess(hash):
            logVerbose(CommitRowAppearanceRules.pushSuccessLogMessage(hash: hash))
        case let .undoSuccess(hash):
            logVerbose(CommitRowAppearanceRules.undoSuccessLogMessage(hash: hash))
        case let .avatarStart(hash):
            logVerbose(CommitRowAppearanceRules.avatarLoadStartLogMessage(hash: hash))
        case let .avatarCoAuthors(hash, count):
            logVerbose(CommitRowAppearanceRules.coAuthorsParsedLogMessage(hash: hash, count: count))
        case let .commitSuccessReloadTag(hash):
            logVerbose(CommitRowAppearanceRules.commitSuccessReloadTagLogMessage(hash: hash))
        }
    }

    func logVerbose(_ message: String) {
        if Self.verbose {
            os_log("\(self.t)\(message)")
        }
    }
}
