import MagicCore
import OSLog
import SwiftUI

struct TileMessage: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MessageProvider

    @State var hovered = false
    @State var isPresented = false
    @State var selection: Set<SmartMessage.ID> = []
    @State var selectedChannel: String = "all"
    @State var messages: [SmartMessage] = []
    
    static var shared = TileMessage()
    
    private init() {}

    var firstFlashMessage: SmartMessage? { m.messages.first(where: { $0.shouldFlash }) }

    var body: some View {
        HStack {
            Image(systemName: "message")
        }
        .onHover(perform: { hovering in
            hovered = hovering
        })
        .onTapGesture {
            self.isPresented.toggle()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hovered ? Color(.controlAccentColor).opacity(0.2) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .popover(isPresented: $isPresented, content: {
            MessageTable()
                .frame(height: 500)
                .frame(width: 1000)
        })
    }
}
