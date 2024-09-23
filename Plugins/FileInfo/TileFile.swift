import SwiftUI
import OSLog

struct TileFile: View, SuperLog, SuperThread {
    @EnvironmentObject var a: AppProvider
    @EnvironmentObject var m: MessageProvider
    
    @State var hovered = false
    @State var isPresented = false
    @State var live = false
    
    var file: File? { a.file }
    var message: SmartMessage? { m.messages.first }

    var body: some View {
        if let file = file {
            HStack {
                Image(systemName: "doc.text").padding(.leading)
                Text(file.name)
                    .padding(.vertical, 4)
            }
        }
    }}
