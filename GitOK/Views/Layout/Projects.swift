import OSLog
import SwiftData
import SwiftUI

struct Projects: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppManager

    @Query(sort: Project.orderReverse) var projects: [Project]

    @State var project: Project? = nil

    var label = "🖥️ ProjectsView::"
    var verbose = false

    var body: some View {
        ZStack {
            List(selection: $project) {
                ForEach(projects, id: \.self) { item in
                    Text(item.title).tag(item as Project?)
                }
                .onDelete(perform: deleteItems)
            }
        }
        .onAppear {
            self.project = projects.first(where: {
                $0.path == AppConfig.projectPath
            })

            if verbose {
                os_log("\(self.label)Set Project=\(project?.title ?? "nil")")
            }

            app.setProject(project)
        }
        .onChange(of: project) {
            app.setProject(project)
        }
        .toolbar(content: {
            ToolbarItem {
                BtnAdd()
            }
        })
        .navigationSplitViewColumnWidth(min: 175, ideal: 175, max: 200)
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
}
