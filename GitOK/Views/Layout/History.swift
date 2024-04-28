import OSLog
import SwiftUI

struct History: View {
    @EnvironmentObject var app: AppManager

    @State var commitId: String = ""
    @State var message = ""
    @State var commits: [GitCommit] = []
    @State var file: File? = nil
    @State var files: [File] = []

    var body: some View {
        if let project = app.project {
            VStack {
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

                List(files, id: \.self, selection: $file) {
                    FileTile(file: $0)
                }
            }
            .onAppear {
                refresh()

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
                
                refreshFile()
            }
            .onChange(of: file, {
                app.file = file
            })
        }
    }

    func refresh() {
        guard let project = app.project else {
            return
        }

        commits = project.getCommits()
        commitId = commits.first?.id ?? ""
        app.commit = project.getCommitsWithHead().first(where: {
            $0.id == commitId
        })
    }

    func refreshFile() {
        guard let commit = app.commit else {
            return
        }

        files = commit.getFiles()
        file = files.first
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
