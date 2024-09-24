import SwiftData
import SwiftUI

struct IconList: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var i: IconProvider

    @State var selection: IconModel = .empty
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
                i.setIcon(self.selection, reason: "IconList.OnChage")
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
            self.icons = IconModel.all(project.path)
            
            if icons.contains(selection) {
                return
            }
            
            self.selection = icons.first ?? .empty
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
