import GitOKCoreFeatures
import MagicAlert
import GitOKSupportKit
import OSLog
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
                try await project.pushAsync()
            },
            undoCommit: { project, commit in
                try await project.undoCommitAsync(commit)
            },
            revertCommit: { project, commit in
                try await project.revertCommitAsync(commit)
            },
            resetToCommit: { project, commit, mode in
                try await project.resetAsync(to: commit, mode: mode)
            },
            squashLastCommits: { project, validation in
                try await project.squashLastCommitsAsync(count: validation.count, message: validation.message)
            },
            loadTags: { project, hash in
                try await project.getTagsAsync(commit: hash)
            },
            createLightweightTag: { project, tagName, commitHash in
                try await project.createLightweightTagAsync(named: tagName, commitHash: commitHash)
            },
            createAnnotatedTag: { project, tagName, commitHash, message in
                try await project.createAnnotatedTagAsync(named: tagName, commitHash: commitHash, message: message)
            },
            deleteLocalTag: { project, tagName in
                try await project.deleteLocalTagAsync(named: tagName)
            },
            pushTagOperation: { project, tagName in
                try await project.pushTagAsync(named: tagName)
            },
            deleteRemoteTag: { project, tagName in
                try await project.deleteRemoteTagAsync(named: tagName)
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
