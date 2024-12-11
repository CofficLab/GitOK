import OSLog
import SwiftData
import SwiftUI
import MagicKit

struct Projects: View, SuperLog {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @Query(sort: Project.order) var projects: [Project]

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
        .onAppear {
            let verbose = false

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
        .onReceive(NotificationCenter.default.publisher(for: .gitProjectDeleted)) { notification in 
            if let path = notification.userInfo?["path"] as? String {
                if self.project?.path == path {
                    self.project = projects.first
                }
            }
        }
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

    private func moveItems(from source: IndexSet, to destination: Int) {
        let itemsToMove = source.map { projects[$0] }
        
        os_log("Moving items: \(itemsToMove.map { $0.title }) from \(source) to \(destination)")

        do {
            // 创建一个临时数组来重新排序
            var tempProjects = projects
            
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
            
            try modelContext.save()
            os_log("Successfully moved items and saved context.")
            
            // 输出所有项目的新顺序
            os_log("New project orders:")
            for (index, project) in projects.enumerated() {
                os_log("Project[\(index)]: \(project.title) - order: \(project.order)")
            }
        } catch {
            os_log("Failed to move items: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
