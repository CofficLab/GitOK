import OSLog
import SwiftData
import SwiftUI
import MagicKit

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
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
