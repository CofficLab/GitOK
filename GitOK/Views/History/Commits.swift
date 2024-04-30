import OSLog
import SwiftUI

struct Commits: View {
    @EnvironmentObject var app: AppManager

    @State var commitId: String = ""
    @State var commits: [GitCommit] = []
    @State var loading = false

    var label: String { "\(Logger.isMain)🖥️ Commits::" }
    var verbose = true

    var body: some View {
        if let project = app.project {
            VStack {
                if loading {
                    Text("loading...")
                } else {
                    List(selection: $commitId) {
                        ForEach(Stage.allCases, id: \.self) { stage in
                            if Stage(rawValue: stage.rawValue) == .Head {
                                Section("当前", content: {
                                    ForEach([project.headCommit]) { commit in
                                        CommitTile(
                                            commit: commit,
                                            project: project
                                        )
                                    }
                                })
                            } else {
                                Section("历史", content: {
                                    ForEach(commits) { commit in
                                        CommitTile(
                                            commit: commit,
                                            project: project
                                        )
                                    }
                                })
                            }
                        }
                    }
                }
            }
            .onAppear {
                refresh("\(self.label)OnApprear")

                EventManager().onCommitted {
                    if verbose {
                        os_log("\(self.label)Refresh because of: Committed")
                    }

                    refresh("\(self.label)OnCommitted")
                }

                EventManager().onRefresh {
                    refresh("\(self.label)OnRefreshButton")
                }
            }
            .onChange(of: commitId, {
                if verbose {
                    os_log("\(self.label)CommitId did set ->\(commitId)")
                }

                guard let project = app.project else {
                    return
                }
                
                if commitId == GitCommit.headId {
                    app.commit = project.headCommit
                } else {
                    app.commit = self.commits.first(where: {
                        $0.id == commitId
                    })
                }
            })
            .onChange(of: app.project, {
                self.refresh("\(self.label)Project Changed")
            })
//            .onChange(of: app.branch, refresh)
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
                self.commitId = commitId
                self.loading = false
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
