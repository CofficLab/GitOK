import SwiftUI

// MARK: - ProjectContextMenu

/// 项目右键菜单
struct ProjectContextMenu: View {
    let item: Project
    let pinAction: (Project) -> Void
    let deleteAction: (Project) -> Void

    var body: some View {
        Button("置顶") {
            pinAction(item)
        }

        if FileManager.default.fileExists(atPath: item.path) {
            Button("在Finder中显示") {
                let url = URL(fileURLWithPath: item.path)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        } else {
            Button("项目已不存在") {}
                .disabled(true)
        }

        Divider()

        Button("删除") {
            deleteAction(item)
        }
    }
}
