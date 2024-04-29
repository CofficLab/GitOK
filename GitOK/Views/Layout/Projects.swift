import SwiftData
import SwiftUI
import OSLog

struct Projects: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppManager

    @Query(sort: [
        SortDescriptor<Project>(\.timestamp, order: .reverse)
    ]) var projects: [Project]
    
    @State var project: Project?
    
    var label = "🖥️ ProjectsView::"

    var body: some View {
        List(selection: $project) {
            ForEach(projects, id: \.self) { item in
                Text(item.title).tag(item as Project?)
            }
            .onDelete(perform: deleteItems)
        }
        .onAppear {
            self.project = projects.first(where: {
                $0.path == AppConfig.projectPath
            })
            os_log("\(self.label)Set Project=\(project?.title ?? "nil")")
            app.setProject(self.project)
        }
        .onChange(of: project, {
            app.setProject(project)
        })
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
