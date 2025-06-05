import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct NoProject: View, SuperThread, SuperEvent {
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var repoManager: RepoManager
    @Environment(\.modelContext) private var modelContext

    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar()
        } detail: {
            VStack(spacing: 20) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("project_not_exist")
                    .font(.title2)
                    .foregroundColor(.secondary)

                if let project = g.project {
                    Button(action: { deleteItem(project) }) {
                        Label("delete_project", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.windowBackgroundColor))
        }
    }

    /**
     * 删除项目
     * @param project 要删除的项目
     */
    private func deleteItem(_ project: Project) {
        withAnimation {
            g.deleteProject(project, using: repoManager.projectRepo)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
