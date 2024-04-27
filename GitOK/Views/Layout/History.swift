import SwiftUI

struct History: View {
    @EnvironmentObject var app: AppManager

    @Binding var selection: GitCommit?

    @State var message = ""
    @State var logs: [GitCommit] = []
    @Binding var file: File?

    var project: Project
    var branch: Branch

    var body: some View {
        VStack {
            HeadTile(file: $file, project: project)

            List(logs, id: \.self, selection: $selection, rowContent: {
                LogTile(
                    commit: $0,
                    project: project,
                    branch: branch
                )
                .tag($0 as GitCommit?)
            })
        }
        .onAppear {
            logs = try! Git.logs(project.path)
            selection = logs.first

            EventManager().onCommitted({
                logs = try! Git.logs(project.path)
            })
        }
        .onChange(of: project, refresh)
        .onChange(of: branch.name, refresh)
        .onChange(of: file, {
            if file != nil {
                selection = nil
            }
        })
        .onChange(of: selection, {
            if selection != nil {
                file = nil
            }
        })
    }

    func refresh() {
        logs = try! Git.logs(project.path)
        if file == nil {
            selection = logs.first
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
