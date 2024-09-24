import SwiftUI
import OSLog

struct TileFile: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var g: GitProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    var file: File? { g.file }
    var message: SmartMessage? { m.messages.first }

    var body: some View {
        if let file = file {
            HStack {
                Image(systemName: "doc.text").padding(.leading)
                Text(file.name).font(.footnote)
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
