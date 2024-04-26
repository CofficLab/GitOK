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
        .onAppear {
            self.branches = Git.getBranches(project.path)
            self.branch = branches.first
        }
        .onChange(of: project, {
            self.branches = Git.getBranches(project.path)
            self.branch = branches.first
        })
        .onChange(of: branch, {
            if let b = branch {
                message = Git.setBranch(b, project.path, debugPrint: true)
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
