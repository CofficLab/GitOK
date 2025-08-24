import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct IconList: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var i: IconProvider

    @State var icons: [IconData] = []
    @State var selection: IconData?

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
        .onChange(of: g.project) {
            self.refreshIcons()
        }
        .onAppear {
            self.refreshIcons()
            self.selection = icons.first
        }
        .onChange(of: selection) { _, newValue in
            i.updateCurrentModel(newModel: newValue)
        }
        .onNotification(.iconDidSave, perform: { _ in
            os_log("iconDidSave while current selection is \(self.selection?.title ?? "nil")")
            let selectedPath = selection?.path
            refreshIcons()

            if self.selection == nil {
                os_log("iconDidSave: no selection, select the first icon")
                self.selection = icons.first
            } else {
                if let selectedPath = selectedPath {
                    selection = icons.first(where: { $0.path == selectedPath })
                }
            }
        })
        .onNotification(.iconDidDelete, perform: { notification in
            self.refreshIcons()

            if let path = notification.userInfo?["path"] as? String {
                if path == self.selection?.path {
                    os_log("iconDidDelete: delete the current selection")
                    self.selection = nil
                }
            }
        })
    }

    func refreshIcons() {
        if let project = g.project {
            icons = ProjectIconRepo.getIconData(from: project)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab("Icon")
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .setInitialTab("Icon")
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
