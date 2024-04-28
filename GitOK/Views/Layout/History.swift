import SwiftUI

struct History: View {
    @EnvironmentObject var app: AppManager

    @Binding var selection: GitCommit?

    @State var message = ""
    @State var commits: [GitCommit] = []
    @Binding var file: File?

    var project: Project
    var branch: Branch

    var body: some View {
        List(selection: $selection) {
            ForEach(Stage.allCases) { stage in
                if Stage(rawValue: stage.rawValue) == .Head {
//                    Section("当前", content: {
//                        HistoryTile(
//                            commit: GitCommit.headFor(project.path),
//                            project: project,
//                            branch: branch
//                        ).tag(GitCommit.headFor(project.path) as GitCommit?)
//                    })
                } else {
                    Section("历史", content: {
                        ForEach(commits) { commit in
                            HistoryTile(
                                commit: commit,
                                project: project,
                                branch: branch
                            ).tag(commit as GitCommit?)
                        }
                    })
                }
            }
            
        }

        .onAppear {
            commits = project.getCommits()
            selection = commits.first

            EventManager().onCommitted {
                commits = project.getCommits()
            }
        }
        .onChange(of: project, refresh)
        .onChange(of: branch.name, refresh)
        .onChange(of: file) {
            if file != nil {
                selection = nil
            }
        }
        .onChange(of: selection) {
            if selection != nil {
                file = nil
            }
        }
    }

    func refresh() {
        commits = try! Git.logs(project.path)
        if file == nil {
            selection = commits.first
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
