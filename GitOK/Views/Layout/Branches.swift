import OSLog
import SwiftUI

struct Branches: View {
    @EnvironmentObject var app: AppProvider

    @State var branches: [Branch] = []
    @State var selection: Branch?

    var label = "🌿 BranchesView::"
    var verbose = true
    var git = Git()

    var body: some View {
        Picker("branch", selection: $selection, content: {
            ForEach(branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
        .onAppear(perform: refresh)
        .onChange(of: app.project, refresh)
        .onChange(of: selection, { oldValue, newValue in
            do {
                try app.setBranch(newValue)
            } catch let error {
                app.alert("切换分支发生错误", info: error.localizedDescription)
                selection = oldValue
            }
        })
    }

    func refresh() {
        guard let project = app.project else {
            return
        }

        if verbose {
            os_log("\(label)Refresh")
        }

        branches = git.getBranches(project.path)
        selection = branches.first(where: {
            $0.name == app.currentBranch?.name
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
