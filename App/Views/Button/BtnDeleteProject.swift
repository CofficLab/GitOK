import SwiftUI
import OSLog

/**
 * 删除项目按钮组件
 */
struct BtnDeleteProject: View {
    @EnvironmentObject var g: DataProvider
//    @EnvironmentObject var repoManager: RepoManager
    
    var project: Project
    
    var body: some View {
        Button(action: { deleteItem(project) }) {
            Label("delete_project", systemImage: "trash")
                .foregroundColor(.red)
        }
        .buttonStyle(.bordered)
    }
    
    /**
     * 删除项目
     * @param project 要删除的项目
     */
    private func deleteItem(_ project: Project) {
        withAnimation {
//            g.deleteProject(project, using: repoManager.projectRepo)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
