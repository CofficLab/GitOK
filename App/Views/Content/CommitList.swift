import OSLog
import SwiftUI

struct CommitList: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var commits: [GitCommit] = []
    @State var loading = false
    @State var selection: GitCommit?
    @State var showCommitForm = false
    @State private var isRefreshing = false

    var label: String { "🖥️ Commits::" }
    var verbose = true

    var body: some View {
        if let project = g.project {
            VStack(spacing: 0) {
                if loading {
                    Spacer()
                    Text("loading...")
                    Spacer()
                } else {
                    List(commits, selection: self.$selection) { commit in
                        CommitTile(commit: commit, project: project).tag(commit)
                    }

                    if showCommitForm {
                        GroupBox {
                            CommitForm2()
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }

                    GroupBox {
                        MergeForm()
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
            }
            .onAppear {
                refresh("\(self.label)OnApprear")
                self.showCommitForm = project.hasUnCommittedChanges()
            }
            .onChange(of: selection, {
                g.setCommit(selection)
            })
            .onChange(of: g.project, {
                self.refresh("\(self.label)Project Changed")
            })
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.commits = [project.headCommit] + project.getCommits("")
            }
//            .onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive)) { _ in
//                self.refresh("\(self.label)AppWillBecomeActive")
//            }
        }
    }

    func refresh(_ reason: String = "") {
        guard let project = g.project, !isRefreshing else {
            return
        }

        isRefreshing = true

        if verbose {
            os_log("\(label)Refresh(\(reason))")
        }

        self.loading = true

        self.bg.async {
            let commits = project.getCommits(reason)

            self.main.async {
                self.commits = [project.headCommit] + commits
                self.loading = false
                self.isRefreshing = false
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
