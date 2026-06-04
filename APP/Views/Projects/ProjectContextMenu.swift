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

        if FileManager.default.fileExists(atPath: item.path) {
            AppContextMenuRow("在Finder中显示", systemImage: "folder") {
                let url = URL(fileURLWithPath: item.path)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        } else {
            AppContextMenuRow("项目已不存在", systemImage: "exclamationmark.triangle") {}
                .disabled(true)
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
}
