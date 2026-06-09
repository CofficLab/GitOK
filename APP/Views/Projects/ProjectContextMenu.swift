import MagicAlert
import GitOKUI
import SwiftUI

// MARK: - ProjectContextMenu

/// 项目右键菜单
struct ProjectContextMenu: View {
    let item: Project
    let pinAction: (Project) -> Void
    let deleteAction: (Project) -> Void

    var body: some View {
        AppContextMenuRow("置顶", systemImage: "pin") {
            pinAction(item)
        }

        AppContextMenuRow("复制项目路径", systemImage: "doc.on.doc") {
            copyProjectPath()
        }

        AppContextMenuRow("在Finder中显示", systemImage: "folder") {
            revealInFinder()
        }

        Divider()

        AppContextMenuRow("删除", systemImage: "trash", role: .destructive) {
            deleteAction(item)
        }
    }

    private func copyProjectPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.path, forType: .string)
        alert_success("已复制项目路径")
    }

    private func revealInFinder() {
        let path = item.path
        Task {
            let exists = await Task.detached(priority: .utility) {
                FileManager.default.fileExists(atPath: path)
            }.value

            guard exists else {
                alert_error("项目已不存在")
                return
            }

            let url = URL(fileURLWithPath: path)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}
