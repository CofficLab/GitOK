import SwiftData
import SwiftUI
import OSLog
import MagicCore

struct IconList: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var i: IconProvider

    @State var selection: IconModel?
    @State var icons: [IconModel] = []

    var body: some View {
        VStack(spacing: 0) {
            List(icons, selection: $selection) { icon in
                IconTile(icon: icon)
                    .contextMenu(ContextMenu(menuItems: {
                        BtnDelIcon(icon: icon, callback: refresh)
                    }))
                    .tag(icon)
            }
            .onChange(of: self.selection, {
                if let path = self.selection?.path, path.isNotEmpty {
                    i.setIconURL(URL(fileURLWithPath: path), reason: "IconList")
                }
            })
            
            // 操作
            if let project = g.project {
                HStack(spacing: 0) {
                    TabBtn(title: "新建 Icon", imageName: "plus.circle", onTap: {
                        self.icons.append(IconModel.new(project))
                    })
                }
                .frame(height: 25)
                .labelStyle(.iconOnly)
            }
        }
        .onChange(of: g.project, refresh)
        .onAppear(perform: refresh)
    }
    
    func refresh() {
        if let project = g.project {
            do {
                self.icons = try project.getIcons()
            
                if let selection = self.selection, icons.contains(selection) {
                    return
                }
                
                self.selection = icons.first ?? .empty
            } catch {
                os_log("Error while enumerating files: \(error.localizedDescription)")
                m.error(error.localizedDescription)
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
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
