import OSLog
import SwiftUI

struct CommitList: View {
    @EnvironmentObject var app: AppProvider

    @State var commits: [GitCommit] = []
    @State var loading = false

    var label: String { "\(Logger.isMain)🖥️ Commits::" }
    var verbose = true

    var body: some View {
        if let project = app.project {
            VStack {
                if loading {
                    Spacer()
                    Text("loading...")
                    Spacer()
                } else {
                    List([project.headCommit] + commits, selection: $app.commit) { commit in
                        CommitTile(commit: commit, project: project)
                            .tag(commit)
                    }
                }
            }
            .onAppear {
                refresh("\(self.label)OnApprear")

                EventManager().onRefresh {
                    refresh("\(self.label)OnRefreshButton")
                }
            }
            .onChange(of: app.project, {
                self.refresh("\(self.label)Project Changed")
            })
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.refresh("\(self.label)GitCommitSuccess")
            }
        }
    }

    func refresh(_ reason: String = "") {
        guard let project = app.project else {
            return
        }

        DispatchQueue.global().async {
            if verbose {
                os_log("\(label)Refresh with reason->\(reason)")
            }

            self.loading = true
            let commits = project.getCommits(reason)
            let commitId = project.headCommit.id

            DispatchQueue.main.async {
                if verbose {
                    os_log("\(label)Update")
                }
                self.commits = commits
//                self.commitId = commitId
                self.loading = false
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
