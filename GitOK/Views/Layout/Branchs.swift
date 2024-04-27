import SwiftUI

struct Branchs: View {
    @EnvironmentObject var app: AppManager
    
    @State var branches: [Branch] = []
    @Binding var branch: Branch?
    @Binding var message: String
    
    var project: Project
    
    var body: some View {
        Picker("branch", selection: $branch, content: {
            ForEach(branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
        .onAppear(perform: refresh)
        .onChange(of: project, refresh)
        .onChange(of: branch, {
            if let b = branch {
                setBranch(b)
            }
        })
    }
    
    func refresh() {
        do {
            try self.branches = Git.getBranches(project.path)
            self.branch = branches.first
        } catch let error {
            app.alert("获取分支发生错误", info: error.localizedDescription)
        }
    }
    
    func setBranch(_ branch: Branch) {
        do {
            try message = Git.setBranch(branch, project.path, debugPrint: true)
        } catch let error {
            app.alert("切换分支发生错误", info: error.localizedDescription)
            self.branch = try! Git.getCurrentBranch(project.path)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
