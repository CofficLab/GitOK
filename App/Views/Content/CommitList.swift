import OSLog
import SwiftUI
import MagicKit

struct CommitList: View, SuperThread, SuperLog{
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var commits: [GitCommit] = []
    @State var loading = false
    @State var selection: GitCommit?
    @State var showCommitForm = false
    @State private var isRefreshing = false

    var emoji = "🖥️"
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
                        CommitTile(commit: commit, project: project, selected: selection).tag(commit)
                    }

                    if showCommitForm {
                        GroupBox {
                            CommitForm()
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(BackgroundView.type2.opacity(0.1))
                    }
                }
            }
            .onAppear {
                refresh("OnAppear")
                self.showCommitForm = project.hasUnCommittedChanges()
            }
            .onChange(of: selection, {
                g.setCommit(selection)
            })
            .onChange(of: g.project, {
                self.refresh("\(self.t)Project Changed")
            })
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                guard let project = g.project else {
                    return
                }
                
                let commits = [project.headCommit] + project.getCommits("")

                self.main.async {
                    self.commits = commits
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitPullSuccess)) { _ in
                self.refresh("\(self.t)GitPullSuccess")
            }
            .onReceive(NotificationCenter.default.publisher(for: .gitPushSuccess)) { _ in
                self.refresh("\(self.t)GitPushSuccess")
            }
//            .onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive)) { _ in
//                self.refresh("\(self.label)AppWillBecomeActive")
//            }
        }
    }

    func refresh(_ reason: String = "") {
        let verbose = false
        
        guard let project = g.project, !isRefreshing else {
            return
        }

        isRefreshing = true

        self.loading = true

        self.bg.async {
            if verbose {
                os_log("\(t)Refresh(\(reason))")
            }
            
            let commits = [project.headCommit] + project.getCommits(reason)

            self.main.async {
                self.commits = commits
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
