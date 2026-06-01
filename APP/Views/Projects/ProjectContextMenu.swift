import MagicAlert
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

        Button("复制项目路径") {
            copyProjectPath()
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

    private func copyProjectPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.path, forType: .string)
        alert_success("已复制项目路径")
    }
}
