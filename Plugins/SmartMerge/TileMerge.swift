import MagicCore
import MagicAlert
import OSLog
import SwiftUI

struct TileMerge: View, SuperLog, SuperThread {
    @EnvironmentObject var m: MagicMessageProvider

    @State var hovered = false
    @State var isPresented = false
    
    static let shared = TileMerge()
    
    private init() {}

    var body: some View {
        HStack {
            Image(systemName: "arrow.trianglehead.merge")
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
            VStack {
                MergeForm().padding()
            }
            .frame(height: 250)
            .frame(width: 200)
        })
    }
}
