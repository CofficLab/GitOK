import SwiftUI

struct History: View {
    @EnvironmentObject var app: AppManager

    @Binding var selection: GitCommit?
    
    @State var message = ""
    @State var logs: [GitCommit] = []

    var item: Project
    var branch: Branch
    var allLogs: [GitCommit] {
        [GitCommit.head] + logs
    }

    var body: some View {
        List(allLogs, id: \.self, selection: $selection, rowContent: {
            LogTile(
                commit: $0,
                project: item,
                branch: branch
            )
                .tag($0 as GitCommit?)
        })
        .onAppear {
            logs = Git.logs(item.path)
            selection = allLogs.first
            
            EventManager().onCommitted({
                logs = Git.logs(item.path)
            })
        }
        .onChange(of: item, {
            logs = Git.logs(item.path)
            selection = allLogs.first
        })
    }
}

#Preview {
    AppPreview()
}
