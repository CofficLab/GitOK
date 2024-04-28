import SwiftUI
import OSLog

struct History: View {
    @EnvironmentObject var app: AppManager

    @State var commitId: String = ""
    @State var message = ""
    @State var commits: [GitCommit] = []
    
    var body: some View {
        if let project = app.project {
            List(selection: $commitId) {
                ForEach(Stage.allCases, id: \.self) { stage in
                    if Stage(rawValue: stage.rawValue) == .Head {
                        Section("当前", content: {
                            ForEach([GitCommit.headFor(project.path)]) { commit in
                                HistoryTile(
                                    commit: commit,
                                    project: project
                                )
                            }
                        })
                    } else {
                        Section("历史", content: {
                            ForEach(commits) { commit in
                                HistoryTile(
                                    commit: commit,
                                    project: project
                                )
                            }
                        })
                    }
                }
            }
            .onAppear {
                commits = project.getCommits()
                commitId = commits.first?.id ?? ""

                EventManager().onCommitted {
                    refresh()
                }
                
                EventManager().onRefresh {
                    refresh()
                }
            }
            .onChange(of: app.project, refresh)
            .onChange(of: app.branch, refresh)
            .onChange(of: commitId) {
                app.commit = project.getCommitsWithHead().first(where: {
                    $0.id == commitId
                })
            }
        }
    }

    func refresh() {
        guard let project = app.project else {
            return
        }
        
        commits = try! Git.logs(project.path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
