import MagicKit
import OSLog
import SwiftData
import SwiftUI

struct Projects: View, SuperLog {
    @EnvironmentObject var data: DataProvider

    static let emoji = "🖥️"

    private let verbose = false

    @State private var selection: Project? = nil

    var body: some View {
        List(selection: $selection) {
            ForEach(data.projects, id: \.self) { item in
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
        .onChange(of: selection, { self.data.setProject(selection, reason: self.className) })
        .onAppear(perform: onAppear)
    }
}

// MARK: - Action

extension Projects {
    private func deleteItem(_ project: Project) {
        withAnimation {
            self.data.deleteProject(project, using: data.repoManager.projectRepo)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                try? self.data.repoManager.projectRepo.delete(data.projects[index])
            }
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        data.moveProjects(from: source, to: destination, using: data.repoManager.projectRepo)
    }
}

// MARK: - Event

extension Projects {
    func onAppear() {
        if verbose {
            os_log("\(self.t)onAppear, projects.count = \(data.projects.count)")
            os_log("\(self.t)Current Project: \(data.project?.path ?? "")")
        }
        self.selection = data.project
    }
}

// MARK: - Preview

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
