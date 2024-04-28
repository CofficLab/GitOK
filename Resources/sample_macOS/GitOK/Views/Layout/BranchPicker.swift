import SwiftUI

struct BranchPicker: View {
    @EnvironmentObject var app: AppManager
    
    @State var branches: [Branch] = []
    @Binding var branch: Branch?
    
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
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
