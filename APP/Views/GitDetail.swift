import GitOKSupportKit
import GitOKCoreFeatures
import SwiftUI

/// Git 详情入口。详情布局和状态逻辑由 CoreKit 的 GitDetailHostView 提供。
struct GitDetail: View, SuperEvent, SuperLog {
    nonisolated static let emoji = "🚄"
    nonisolated static let verbose = true

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var projectChangeToken = 0
    @State private var appWillBecomeActiveToken = 0

    var body: some View {
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
                FileList()
            },
            fileDetailContent: {
                FileDetail()
            },
            emptyContent: {
                NoLocalChanges()
            },
            notGitContent: {
                ProjectNotGitView()
            },
            commitFormContent: {
                CommitForm()
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
