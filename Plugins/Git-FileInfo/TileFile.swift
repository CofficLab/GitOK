import SwiftUI
import OSLog
import MagicCore

struct TileFile: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var data: DataProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    var file: File? { data.file }
    var message: SmartMessage? { m.messages.first }

    var body: some View {
        if let file = file, a.currentTab == "Git" {
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

#Preview("默认") {
    RootView {
        ContentView()
    }
    .frame(height: 600)
    .frame(width: 600)
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
