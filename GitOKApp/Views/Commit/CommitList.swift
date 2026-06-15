import GitOKAppCore
import GitWorkspacePlugin
import GitOKSupportKit
import OSLog
import SwiftUI

/// Git 提交列表视图组件
struct CommitList: View, SuperLog {
    nonisolated static let emoji = "🖥️"
    nonisolated static let verbose = false

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var refreshToken = 0
    @State private var refreshReason = CommitListPaginationRules.appearRefreshReason

    private let commitRepo = GitCommitRepo.shared

    var body: some View {
        let projectPath = vm.project?.path

        CommitListHostView(
            project: vm.project,
            projectPath: \.path,
            loadItems: { project, page, limit in
                try await project.getCommitGraphWithPaginationAsync(page, limit: limit)
            },
            loadUnpushedItems: { project in
                try await project.getUnPushedCommitHashesAsync()
            },
            itemID: \.hash,
            itemParentIDs: \.parentHashes,
            unpushedID: { $0 },
            updateUnpushed: { count, hashes in
                vm.updateUnpushedCommits(count, hashes: hashes, projectPath: projectPath)
            },
            selectItem: { commit in
                data.setCommit(commit)
            },
            loadLastSelectedID: commitRepo.getLastSelectedCommitHash(projectPath:),
            logEvent: logEvent(_:),
            refreshToken: refreshToken,
            refreshReason: refreshReason
        ) { isRefreshing in
            WorkingStateView(isRefreshing: isRefreshing)
        } rowContent: { commit, isFirstCommit, index, graphRow, graphLaneCount in
            CommitRow(
                commit: commit,
                isFirstCommit: isFirstCommit,
                commitIndex: index,
                graphRow: graphRow,
                graphLaneCount: graphLaneCount
            )
        }
        .onChange(of: vm.project) {
            performRefreshEvent(.projectChanged)
        }
        .onProjectDidChangeBranch { _ in
            performRefreshEvent(.branchChanged)
        }
        .onProjectDidCommit { _ in
            performRefreshEvent(.commitSuccess)
        }
        .onProjectDidPull { _ in
            performRefreshEvent(.pullSuccess)
        }
        .onProjectDidPush { _ in
            performRefreshEvent(.pushSuccess)
        }
        .onProjectGitHeadDidChange(perform: onGitDirectoryDidChange)
        .onApplicationWillBecomeActive {
            performRefreshEvent(.applicationWillBecomeActive)
        }
    }
}

private extension CommitList {
    func logEvent(_ event: CommitListHostLogEvent) {
        switch event {
        case .refresh(let reason):
            if Self.verbose {
                os_log("\(Self.t)\(CommitListPaginationRules.refreshLogMessage(reason: reason))")
            }
        case .loadMoreFailure(let error):
            os_log(.error, "\(Self.t)\(CommitListPaginationRules.loadMoreFailureLogMessage(errorDescription: String(describing: error)))")
        case .duplicateLoadMore:
            if Self.verbose {
                os_log("\(Self.t)\(CommitListPaginationRules.duplicateLoadMoreWarningLogMessage())")
            }
        }
    }

    func onGitDirectoryDidChange(_ eventInfo: ProjectEventInfo) {
        CommitListPaginationRules.performGitDirectoryChangedRefreshEvent(
            eventProjectPath: eventInfo.project.path,
            currentProject: vm.project,
            currentProjectPath: \.path,
            didHeadChange: eventInfo.additionalInfo?[CommitListPaginationRules.gitHeadChangedEventInfoKey] as? Bool == true,
            refresh: { reason in
                refreshReason = reason
                refreshToken += 1
            }
        )
    }

    func performRefreshEvent(_ event: CommitListPaginationRules.RefreshEvent) {
        CommitListPaginationRules.performRefreshEvent(event) { reason in
            refreshReason = reason
            refreshToken += 1
        }
    }
}
