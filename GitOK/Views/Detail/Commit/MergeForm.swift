import SwiftUI

struct MergeForm: View {
    @EnvironmentObject var app: AppProvider

    @State var branches: [Branch] = []
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var branch1: Branch? = nil
    @State var branch2: Branch? = nil

    var project: Project? { app.project }
    var git = Git()

    var body: some View {
        if let project = project {
            Group {
                HStack {
                    Picker("from", selection: $branch1, content: {
                        ForEach(branches, id: \.self, content: {
                            Text($0.name)
                                .tag($0 as Branch?)
                        })
                    })
                    
                    Picker("to", selection: $branch2, content: {
                        ForEach(branches, id: \.self, content: {
                            Text($0.name)
                                .tag($0 as Branch?)
                        })
                    })

                    if let branch1 = branch1, let branch2 = branch2 {
                        BtnMerge(path: project.path, from: branch1, to: branch2)
                    }
                }
            }
            .onAppear(perform: {
                self.branches = git.getBranches(project.path)
                self.branch1 = branches.first
                self.branch2 = branches.count >= 2 ? branches[1] : branches.first

                EventManager().onCommitted {
                    self.text = ""
                }
            })
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
