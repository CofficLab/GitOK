import OSLog
import SwiftUI

struct Commits: View {
    @EnvironmentObject var app: AppManager

    @State var commitId: String = ""
    @State var commits: [GitCommit] = []
    
    var label = "🖥️ Commits::"
    var verbose = false

    var body: some View {
        if let project = app.project {
            VStack {
                List(selection: $commitId) {
                    ForEach(Stage.allCases, id: \.self) { stage in
                        if Stage(rawValue: stage.rawValue) == .Head {
                            Section("当前", content: {
                                ForEach([GitCommit.headFor(project.path)]) { commit in
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
            .onAppear {
                refresh()

//                EventManager().onCommitted {
//                    if verbose {
//                        os_log("\(self.label)Refresh because of: Committed")
//                    }
//                    
//                    refresh()
//                }

                EventManager().onRefresh {
                    refresh()
                }
            }
            .onChange(of: commitId, {
                if verbose {
                    os_log("\(self.label)CommitId did set ->\(commitId)")
                }
                
                guard let project = app.project else {
                    return
                }
                
                app.commit = project.getCommitsWithHead().first(where: {
                    $0.id == commitId
                })
            })
//            .onChange(of: app.project, refresh)
//            .onChange(of: app.branch, refresh)
        }
    }

    func refresh() {
        guard let project = app.project else {
            return
        }

        commits = project.getCommits()
        commitId = commits.first?.id ?? ""
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
