import OSLog
import MagicKit
import SwiftUI

struct MergeForm: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider

    @State var branches: [GitBranch] = []
    @State var text: String = ""
    @State var category: CommitCategory = .Chore
    @State var branch1: GitBranch? = nil
    @State var branch2: GitBranch? = nil

    var project: Project? { g.project }

    var body: some View {
        if let project = project {
            Group {
                VStack {
                    VStack {
                        Picker("", selection: $branch1, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as GitBranch?)
                            })
                        })

                        Text("to").padding()

                        Picker("", selection: $branch2, content: {
                            ForEach(branches, id: \.self, content: {
                                Text($0.name)
                                    .tag($0 as GitBranch?)
                            })
                        })
                    }

                    if let branch1 = branch1, let branch2 = branch2 {
                        BtnMerge(path: project.path, from: branch1, to: branch2)
//                            .padding(.top, 20)
//                            .controlSize(.extraLarge)
                    }
                }
            }
            .onAppear(perform: {
                do {
                    self.branches = try project.getBranches()
                    self.branch1 = branches.first
                    self.branch2 = branches.count >= 2 ? branches[1] : branches.first
                } catch let error {
                    os_log(.error, "\(error.localizedDescription)")
                }
            })
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
