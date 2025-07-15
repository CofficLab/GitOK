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

    var body: some View {
        VStack(spacing: 0) {
            List(icons, selection: $selection) { icon in
                IconTile(icon: icon)
                    .contextMenu(ContextMenu(menuItems: {
                        BtnDelIcon(icon: icon, callback: {
                            self.refreshIcons()
                        })
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
            let selectedPath = selection?.path
            refreshIcons()
            if let selectedPath = selectedPath {
                selection = icons.first(where: { $0.path == selectedPath })
            }
        })
    }

    func refreshIcons() {
        if let project = g.project {
            do {
                self.icons = try project.getIcons()
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
