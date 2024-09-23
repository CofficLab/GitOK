import SwiftData
import SwiftUI

struct IconList: View {
    @EnvironmentObject var app: AppProvider

    @State var selection: IconModel = .empty
    @State var icons: [IconModel] = []

    var body: some View {
        VStack(spacing: 0) {
            List(icons, selection: $selection) { icon in
                IconTile(icon: icon, selected: self.selection)
                    .contextMenu(ContextMenu(menuItems: {
                        BtnDelIcon(icon: icon, callback: refresh)
                    }))
                    .tag(icon)
            }
            
            // 操作
            if let project = app.project {
                HStack(spacing: 0) {
                    TabBtn(title: "新建 Icon", imageName: "plus.circle", onTap: {
                        self.icons.append(IconModel.new(project))
                    })
                }
                .frame(height: 25)
                .labelStyle(.iconOnly)
            }
        }
        .onChange(of: app.project, refresh)
        .onAppear(perform: refresh)
    }
    
    func refresh() {
        if let project = app.project {
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
