import MagicKit
import OSLog
import SwiftData
import SwiftUI

struct NoProject: View, SuperThread, SuperEvent {
    @EnvironmentObject var g: GitProvider
    @Environment(\.modelContext) private var modelContext

    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                Sidebar()
            } detail: {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("项目不存在")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    if let project = g.project {
                        Button(action: { deleteItem(project) }) {
                            Label("删除项目", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.windowBackgroundColor))
            }

            Message()
        }
    }
    
    private func deleteItem(_ project: Project) {
        let path = project.path
        withAnimation {
            modelContext.delete(project)
            self.emitGitProjectDeleted(path: path)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}