import OSLog
import SwiftUI

struct CommitList: View, SuperThread {
    @EnvironmentObject var app: AppProvider

    @State var commits: [GitCommit] = []
    @State var loading = false
    @State var selection: GitCommit?

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
                    GroupBox {
                        if selection?.getFiles().isNotEmpty ?? false {
                            CommitForm2().padding()
                        }
                        
                        MergeForm().padding()
                    }.padding()
                    
                    List([project.headCommit] + commits, selection: self.$selection) { commit in
                        CommitTile(commit: commit, project: project).tag(commit)
                    }
                }
            }
            .onAppear {
                refresh("\(self.label)OnApprear")
            }
            .onChange(of: selection, {
                app.setCommit(selection)
            })
            .onChange(of: app.project, {
                self.refresh("\(self.label)Project Changed")
            })
            .onReceive(NotificationCenter.default.publisher(for: .gitCommitSuccess)) { _ in
                self.refresh("\(self.label)GitCommitSuccess")
            }
//            .onReceive(NotificationCenter.default.publisher(for: .appWillBecomeActive)) { _ in
//                self.refresh("\(self.label)AppWillBecomeActive")
//            }
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

        self.bg.async {
            let commits = project.getCommits(reason)

            self.main.async {
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
