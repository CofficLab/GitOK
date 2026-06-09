
import OSLog
import GitOKCoreKit
import SwiftUI

struct IconList: View {
    let projectURL: URL?
    @EnvironmentObject var i: IconProvider

    @State var icons: [IconData] = []
    @State var selection: IconData?

    init(projectURL: URL?) {
        self.projectURL = projectURL
    }

    static let emoji = "🐈"

    var body: some View {
        VStack(spacing: 0) {
            List(icons, selection: $selection) { icon in
                IconTile(icon: icon)
                    .contextMenu(ContextMenu(menuItems: {
                        BtnDelIcon(icon: icon)
                    }))
                    .tag(icon)
            }

            IconListActions()
        }
        .onChange(of: projectURL) {
            self.refreshIcons(selectFirstWhenNeeded: true)
        }
        .onAppear {
            self.refreshIcons(selectFirstWhenNeeded: true)
        }
        .onChange(of: selection) { _, newValue in
            i.updateCurrentModel(newModel: newValue)
        }
        .onNotification(.iconDidSave, perform: { _ in
            #if DEBUG
            os_log("iconDidSave while current selection is \(self.selection?.title ?? "nil")")
            #endif
            let selectedPath = selection?.path
            refreshIcons(preferredSelectionPath: selectedPath, selectFirstWhenNeeded: true)
        })
        .onNotification(.iconDidDelete, perform: { notification in
            let deletedSelectionPath = notification.userInfo?["path"] as? String
            self.refreshIcons(
                preferredSelectionPath: selection?.path,
                selectFirstWhenNeeded: deletedSelectionPath == self.selection?.path
            )
        })
    }

    func refreshIcons(
        preferredSelectionPath: String? = nil,
        selectFirstWhenNeeded: Bool = false
    ) {
        guard let projectURL else {
            icons = []
            selection = nil
            return
        }

        Task {
            let loadedIcons = await ProjectIconRepo.getIconDataAsync(from: projectURL)

            await MainActor.run {
                guard self.projectURL == projectURL else { return }
                icons = loadedIcons

                if let preferredSelectionPath,
                   let preferredSelection = loadedIcons.first(where: { $0.path == preferredSelectionPath }) {
                    selection = preferredSelection
                } else if selectFirstWhenNeeded, selection == nil || loadedIcons.contains(selection!) == false {
                    #if DEBUG
                    os_log("refreshIcons: select the first icon")
                    #endif
                    selection = loadedIcons.first
                }
            }
        }
    }
}
