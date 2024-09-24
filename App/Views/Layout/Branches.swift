import OSLog
import SwiftUI

struct Branches: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var branches: [Branch] = []
    @State var selection: Branch?

    var emoji = "🌿"
    var git = Git()

    var body: some View {
        Picker("branch", selection: $selection, content: {
            Text("None").tag(nil as Branch?) // Add a default tag for nil
            ForEach(branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
        .onAppear(perform: refresh)
        .onChange(of: g.project, refresh)
        .onChange(of: selection, setBranch)
    }

    func setBranch() {
        self.bg.async {
            do {
                try g.setBranch(selection)
            } catch let error {
                app.alert("切换分支发生错误", info: error.localizedDescription)
                self.refresh()
            }
        }
    }

    func refresh() {
        let verbose = false
        
        guard let project = g.project else {
            return
        }

        if verbose {
            os_log("\(t)Refresh")
        }

        do {
            branches = try git.getBranches(project.path)
        } catch let error {
            os_log(.error, "\(error.localizedDescription)")
        }

        selection = branches.first(where: {
            $0.name == g.currentBranch?.name
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
