import OSLog
import SwiftUI

struct CommitList: View, SuperThread {
    @EnvironmentObject var app: AppProvider

    @State var commits: [GitCommit] = []
    @State var loading = false

    var label: String { "🖥️ Commits::" }
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
            }
            .onChange(of: app.project, {
                self.refresh("\(self.label)Project Changed")
            })
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.refresh("\(self.label)GitCommitSuccess")
            }
            .onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive)) { _ in
                self.refresh("\(self.label)AppWillBecomeActive")
            }
        }
    }

    func refresh(_ reason: String = "") {
        guard let project = app.project else {
            return
        }

        if verbose {
            os_log("\(label)Refresh with reason->\(reason)")
        }

        self.loading = true

        DispatchQueue.global().async {
            let commits = project.getCommits(reason)

            DispatchQueue.main.async {
                self.commits = commits
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
