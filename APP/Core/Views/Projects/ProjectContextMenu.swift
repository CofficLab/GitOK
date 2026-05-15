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

            if let xcodeProjectURL {
                Button("在 Xcode 中打开") {
                    openInXcode(xcodeProjectURL)
                }
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

    private var xcodeProjectURL: URL? {
        let projectURL = URL(fileURLWithPath: item.path)
        let fileExtension = projectURL.pathExtension.lowercased()
        if fileExtension == "xcworkspace" || fileExtension == "xcodeproj" {
            return projectURL
        }

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        if let workspace = contents
            .filter({ $0.pathExtension.lowercased() == "xcworkspace" })
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .first {
            return workspace
        }

        return contents
            .filter { $0.pathExtension.lowercased() == "xcodeproj" }
            .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            .first
    }

    private func openInXcode(_ url: URL) {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Xcode.app")) else {
            return
        }

        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: nil
        )
    }
}
