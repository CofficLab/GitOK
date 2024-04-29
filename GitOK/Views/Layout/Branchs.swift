import SwiftUI

struct Branchs: View {
    @EnvironmentObject var app: AppManager

    @State var branches: [Branch] = []

    var body: some View {
        Picker("branch", selection: $app.branch, content: {
            ForEach(branches, id: \.self, content: {
                Text($0.name)
                    .tag($0 as Branch?)
            })
        })
        .onAppear(perform: refresh)
        .onChange(of: app.project, refresh)
        .onChange(of: app.branch, {
            if let b = app.branch {
                setBranch(b)
            }
        })
    }

    func refresh() {
        guard let project = app.project else {
            return
        }
        
        do {
            try branches = Git.getBranches(project.path)
            app.branch = branches.first(where: { $0.isCurrent })
        } catch let error {
            app.alert("获取分支发生错误", info: error.localizedDescription)
        }
    }

    func setBranch(_ branch: Branch) {
        guard let project = app.project else {
            return
        }
        
        do {
            let current = try Git.getCurrentBranch(project.path)
            if current.name == branch.name {
                return
            }
            
            _ = try Git.setBranch(branch, project.path, verbose: true)
        } catch let error {
            DispatchQueue.main.async {
                app.branch = try! Git.getCurrentBranch(project.path)
            }
            
            app.alert("切换分支发生错误", info: error.localizedDescription)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
