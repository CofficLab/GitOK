import SwiftUI

struct MergeForm: View {
    @EnvironmentObject var app: AppManager

    @Binding var message: String

    @State var branches: [Branch] = []
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var branch1: Branch? = nil
    @State var branch2: Branch? = nil

    var project: Project

    var commitMessage: String {
        var c = text
        if c.isEmpty {
            c = "Auto Committed by GitOK"
        }

        return "\(category.text) \(c)"
    }

    var body: some View {
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
                    BtnMerge(message: $message, path: project.path, from: branch1, to: branch2)
                }
            }
        }
        .onAppear(perform: {
            self.branches = try! Git.getBranches(project.path)
            self.branch1 = branches.first
            self.branch2 = branches.first

            EventManager().onCommitted {
                self.text = ""
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
