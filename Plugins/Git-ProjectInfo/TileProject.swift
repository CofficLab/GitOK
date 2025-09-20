import SwiftUI
import OSLog
import MagicAlert
import MagicCore

struct TileProject: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var data: DataProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    static let shared = TileProject()
    
    private init() {}
    
    var project: Project? { data.project }

    var body: some View {
        if let project = project, data.file == nil {
            HStack {
                Image(systemName: "folder").padding(.leading)
                Text(project.path).font(.footnote)
            }
            .onHover(perform: { hovering in
                hovered = hovering
            })
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
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

