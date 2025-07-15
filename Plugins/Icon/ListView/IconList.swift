import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct IconList: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var i: IconProvider

    @State var icons: [IconModel] = []
    @State var selection: IconModel?

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
        .onChange(of: selection, {
            i.updateCurrentModel(newModel: selection, reason: "IconList.selection")
        })
        .onNotification(.iconDidSave, perform: { _ in
            os_log("\(self.t)iconDidSave while current selection is \(self.selection?.title ?? "nil")")
            let selectedPath = selection?.path
            refreshIcons()

            if self.selection == nil {
                os_log("\(self.t)iconDidSave: no selection, select the first icon")
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
                    os_log("\(self.t)iconDidDelete: delete the current selection")
                    self.selection = nil
                }
            }
        })
    }

    func refreshIcons() {
        if let project = g.project {
            do {
                let icons = try project.getIcons()
                // 按照path排序
                self.icons = icons.sorted(by: { $0.path < $1.path })
            } catch {
                os_log(.error, "Error while enumerating files: \(error.localizedDescription)")
                m.error(error.localizedDescription)
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
