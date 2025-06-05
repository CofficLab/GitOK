import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct Projects: View, SuperLog {
    @EnvironmentObject var repoManager: RepoManager
    @EnvironmentObject var g: DataProvider

    static let emoji = "🖥️"

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
}

// MARK: - Action

extension Projects {
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
        // 直接调用 GitProvider 的排序方法
        g.moveProjects(from: source, to: destination, using: repo)
    }
}

// MARK: - Event

extension Projects {
    func onAppear() {
        os_log("\(self.t)onAppear, projects.count = \(g.projects.count)")
        os_log("\(self.t)Current Project: \(g.project?.path ?? "")")
    }
}

// MARK: - Preview

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
