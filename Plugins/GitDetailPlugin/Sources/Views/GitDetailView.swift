import GitOKAppCore
import GitOKSupportKit
import SwiftUI

/// Git 详情入口。详情布局和状态逻辑由 GitDetailHostView 提供。
public struct GitDetailView: View, SuperEvent, SuperLog {
    nonisolated public static let emoji = "🚄"
    nonisolated public static let verbose = false

    @EnvironmentObject private var data: DataVM
    @EnvironmentObject private var vm: ProjectVM

    @State private var projectChangeToken = 0
    @State private var appWillBecomeActiveToken = 0

    public init() {}

    public var body: some View {
        GitDetailHostView(
            project: vm.project,
            selectedCommit: data.commit,
            isClean: vm.isClean,
            projectIsGitRepository: { _ in
                vm.currentProjectIsGitRepository || vm.isCheckingCurrentProjectGitRepository
            },
            commitMessage: \.message,
            commitBodyText: \.body,
            commitAuthor: \.author,
            commitDate: \.date,
            commitHash: \.hash,
            projectChangeToken: projectChangeToken,
            appWillBecomeActiveToken: appWillBecomeActiveToken,
            commitInfoContent: { state in
                CommitInfoView(
                    message: state.message,
                    bodyText: state.bodyText,
                    author: state.author,
                    date: state.date,
                    hash: state.hash
                )
            },
            fileListContent: {
                FileListView()
            },
            fileDetailContent: {
                FileDetailView()
            },
            emptyContent: {
                GitDetailNoLocalChangesView()
            },
            notGitContent: {
                GitDetailNotRepositoryView()
            },
            commitFormContent: {
                CommitFormView()
            }
        )
        .onChange(of: vm.project) {
            projectChangeToken += 1
        }
        .onChange(of: vm.projectGitRepositoryStateToken) {
            projectChangeToken += 1
        }
        .onApplicationWillBecomeActive {
            appWillBecomeActiveToken += 1
        }
    }
}
