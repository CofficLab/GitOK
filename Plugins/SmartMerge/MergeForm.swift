import OSLog
import SwiftUI

struct MergeForm: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var branches: [Branch] = []
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var branch1: Branch? = nil
    @State var branch2: Branch? = nil

    var project: Project? { g.project }
    var git = GitShell()

    var body: some View {
        if let project = project {
            Group {
                VStack {
                    VStack {
                        Picker("", selection: $branch1, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as Branch?)
                            })
                        })

                        Text("to").padding()

                        Picker("", selection: $branch2, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as Branch?)
                            })
                        })
                    }

                    if let branch1 = branch1, let branch2 = branch2 {
                        BtnMerge(path: project.path, from: branch1, to: branch2)
                            .padding(.top, 20)
                            .controlSize(.extraLarge)
                    }
                }
            }
            .onAppear(perform: {
                do {
                    self.branches = try GitShell.getBranches(project.path)
                    self.branch1 = branches.first
                    self.branch2 = branches.count >= 2 ? branches[1] : branches.first
                } catch let error {
                    os_log(.error, "\(error.localizedDescription)")
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
