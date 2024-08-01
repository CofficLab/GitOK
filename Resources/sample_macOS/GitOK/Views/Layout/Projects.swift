import SwiftData
import SwiftUI

struct Projects: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppManager

    @Query(sort: [
        SortDescriptor<Project>(\.timestamp, order: .reverse)
    ]) var projects: [Project]

    @Binding var project: Project?
    @State var branch: Branch? = nil
    @State var gitLog: GitCommit? = nil
    @State var message: String = ""

    var body: some View {
        List(selection: $project) {
            ForEach(projects, id: \.self) { item in
                Text(item.title).tag(item as Project?)
            }
            .onDelete(perform: deleteItems)
        }
        .onAppear {
            project = projects.first
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
