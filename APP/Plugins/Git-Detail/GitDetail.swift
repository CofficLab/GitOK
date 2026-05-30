import MagicKit
import PluginCommit
import PluginGitDetail
import SwiftUI

/// Git 详情入口。详情布局和状态逻辑在 PluginGitDetail 的 GitDetailHostView 中。
struct GitDetail: View, SuperEvent, SuperLog {
    nonisolated static let emoji = "🚄"
    nonisolated static let verbose = true

    @EnvironmentObject var data: DataVM
    @EnvironmentObject var vm: ProjectVM

    @State private var projectChangeToken = 0
    @State private var appWillBecomeActiveToken = 0

    static let shared = GitDetail()

    var body: some View {
        GitDetailHostView(
            project: vm.project,
            selectedCommit: data.commit,
            isClean: vm.isClean,
            projectIsGitRepository: { $0.isGit() },
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
        .onApplicationWillBecomeActive {
            appWillBecomeActiveToken += 1
        }
    }
}
