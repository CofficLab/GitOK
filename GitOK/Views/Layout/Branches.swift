import SwiftUI
import OSLog

struct Branches: View {
    @EnvironmentObject var app: AppManager

    @State var branches: [Branch] = []
    @State var selection: Branch?
    
    var label = "🌿 BranchesView::"
    var verbose = true

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
            os_log("\(self.label)Refresh")
        }
        
        do {
            try branches = Git.getBranches(project.path)
            self.selection = branches.first(where: {
                $0.name == app.currentBranch?.name
            })
        } catch let error {
            app.alert("获取分支发生错误", info: error.localizedDescription)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
