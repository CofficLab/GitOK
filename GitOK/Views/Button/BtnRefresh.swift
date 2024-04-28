import SwiftUI

struct BtnRefresh: View {
    @Binding var message: String
    
    var path: String
    
    var body: some View {
        Button(action: {
            EventManager().emitRefresh()
        }, label: {
            Label("刷新", systemImage: "arrow.clockwise.circle")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
