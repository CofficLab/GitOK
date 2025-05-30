import SwiftUI
import OSLog
import MagicCore

struct TileProject: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var g: GitProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    var project: Project? { g.project }
    var message: SmartMessage? { m.messages.first }

    var body: some View {
        if let project = project, g.file == nil {
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

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
