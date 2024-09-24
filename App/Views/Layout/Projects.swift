import OSLog
import SwiftData
import SwiftUI

struct Projects: View, SuperLog {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @Query(sort: Project.orderReverse) var projects: [Project]

    @State var project: Project? = nil

    var emoji = "🖥️"

    var body: some View {
        ZStack {
            List(selection: $project) {
                ForEach(projects, id: \.self) { item in
                    Text(item.title).tag(item as Project?)
                        .contextMenu(ContextMenu(menuItems: {
                            Button("删除") {
                                deleteItem(item)
                            }
                        }))
                }
                .onDelete(perform: deleteItems)
            }
        }
        .onAppear {
            let verbose = true
            
            self.project = projects.first(where: {
                $0.path == AppConfig.projectPath
            })

            if verbose {
                os_log("\(self.t)Set Project ➡️ \(project?.title ?? "nil")")
            }

            g.setProject(project, reason: "Projects.OnAppear")
        }
        .onChange(of: project) {
            g.setProject(project, reason: "Projects.OnChangeOfProject")
        }
        .navigationSplitViewColumnWidth(min: 175, ideal: 175, max: 200)
    }
                                                 
    private func deleteItem(_ project: Project) {
         withAnimation {
                modelContext.delete(project)
         }
     }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
