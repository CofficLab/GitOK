import OSLog
import SwiftData
import SwiftUI
import MagicCore

struct Projects: View, SuperLog {
    @EnvironmentObject var repoManager: RepoManager
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    var emoji = "🖥️"
    
    private var repo: any ProjectRepoProtocol { repoManager.projectRepo }

    var body: some View {
        ZStack {
            List(selection: $g.project) {
                ForEach(g.projects, id: \.self) { item in
                    Text(item.title).tag(item as Project?)
                        .contextMenu(ContextMenu(menuItems: {
                            Button("删除") {
                                deleteItem(item)
                            }
                            
                            if FileManager.default.fileExists(atPath: item.path) {
                                Button("在Finder中显示") {
                                    let url = URL(fileURLWithPath: item.path)
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                }
                            } else {
                                Button("项目已不存在") {
                                    // 禁止点击
                                }
                                .disabled(true)
                            }
                        }))
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
        }
        .onAppear(perform: onAppear)
        .navigationSplitViewColumnWidth(min: 175, ideal: 175, max: 200)
    }

    private func deleteItem(_ project: Project) {
        withAnimation {
            try? self.repo.delete(project)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                try? self.repo.delete(g.projects[index])
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        let itemsToMove = source.map { g.projects[$0] }
        
        os_log("Moving items: \(itemsToMove.map { $0.title }) from \(source) to \(destination)")

        do {
            // 创建一个临时数组来重新排序
            var tempProjects = g.projects
            
            // 从原位置移除项目
            for index in source.sorted(by: >) {
                tempProjects.remove(at: index)
            }
            
            // 修改：确保目标索引不会超出数组范围
            let safeDestination = min(destination, tempProjects.count)
            
            // 在目标位置插入项目
            for item in itemsToMove.reversed() {
                tempProjects.insert(item, at: safeDestination)
            }
            
            // 更新所有项目的order值
            for (index, project) in tempProjects.enumerated() {
                project.order = Int16(index)
            }
            
//            try modelContext.save()
            os_log("Successfully moved items and saved context.")
            
            // 输出所有项目的新顺序
            os_log("New project orders:")
            for (index, project) in g.projects.enumerated() {
                os_log("Project[\(index)]: \(project.title) - order: \(project.order)")
            }
        } catch {
            os_log("Failed to move items: \(error.localizedDescription)")
        }
    }
}

// MARK: - Event

extension Projects {
    func onAppear() {
        os_log("\(self.t) onAppear, projects.count = \(g.projects.count)")
        os_log("\(self.t)Current Project: \(g.project?.path ?? "")")
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
