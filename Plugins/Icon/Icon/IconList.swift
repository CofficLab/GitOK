import SwiftData
import SwiftUI

struct IconList: View {
    @EnvironmentObject var app: AppManager

    @State var icon: IconModel?
    @State var icons: [IconModel] = []

    var body: some View {
        VStack(spacing: 0) {
            List(icons, id: \.self, selection: $icon) { icon in
                Text(icon.title)
                    .contextMenu(ContextMenu(menuItems: {
                        BtnDelIcon(icon: icon, callback: refresh)
                    }))
            }
            
            // 操作
            if let project = app.project {
                HStack(spacing: 0) {
                    TabBtn(title: "新建 Banner", imageName: "plus.circle", onTap: {
                        self.icons.append(IconModel.new(project))
                    })
                }
                .frame(height: 25)
                .labelStyle(.iconOnly)
            }
        }
        .onChange(of: icon) {
            app.icon = icon
            refresh()
        }
        .onChange(of: app.project, refresh)
        .onAppear(perform: refresh)
    }
    
    func refresh() {
        if let project = app.project {
            self.icons = IconModel.all(project.path)
            
            if let i = self.icon, icons.contains(i) {
                return
            }
            
            self.icon = icons.first
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
