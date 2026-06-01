import MagicAlert
import MagicKit
import OSLog
import GitOKCoreFeatures
import SwiftUI

/// 提交表单视图组件
struct CommitForm: View, SuperLog {
    nonisolated static let emoji = "📝"
    nonisolated static let verbose = false

    @EnvironmentObject var g: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var commitResetToken = 0
    @State private var autocompleteRefreshToken = 0

    var body: some View {
        CommitFormHostView(
            project: vm.project,
            projectStyle: \.commitStyle,
            saveProjectStyle: { project, style in
                project.commitStyle = style
            },
            loadCoAuthors: {
                CoAuthorStore.shared.loadCoAuthors()
            },
            loadLocalBranches: { project in
                try project.getBranches()
            },
            localBranchName: \.name,
            loadRemoteBranches: { project in
                try project.remoteBranches()
            },
            hasStagedChanges: { project in
                try project.hasStagedChanges()
            },
            addAllFiles: { project in
                try project.addAll()
            },
            commit: { project, plan in
                try await MainActor.run {
                    try project.submit(plan.message)
                }
            },
            push: { project in
                try project.push()
            },
            setActivityStatus: { status in
                g.activityStatus = status
            },
            eventHandler: handleEvent(_:),
            commitResetToken: commitResetToken,
            autocompleteRefreshToken: autocompleteRefreshToken
        ) {
            UserView()
        }
        .onProjectDidCommit { _ in
            commitResetToken += 1
        }
        .onChange(of: vm.project) {
            autocompleteRefreshToken += 1
        }
        .onProjectDidChangeBranch { _ in
            autocompleteRefreshToken += 1
        }
        .onProjectGitRefsDidChange { _ in
            autocompleteRefreshToken += 1
        }
    }
}

private extension CommitForm {
    func handleEvent(_ event: CommitFormHostEvent) {
        switch event {
        case .showInfoMessage(let message):
            CommitAlertRules.performInfo(message) {
                alert_info($0)
            }
        case .showError(let error):
            CommitAlertRules.performError(error) {
                alert_error($0)
            }
        case .submitFailure(let error):
            os_log(.error, "\(Self.t)\(CommitMessageRules.submitFailureLogMessage(errorDescription: error.localizedDescription))")
        }
    }
}
