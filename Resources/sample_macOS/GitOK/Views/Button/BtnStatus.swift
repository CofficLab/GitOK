import SwiftUI

struct BtnStatus: View {
    @Binding var message: String
    
    var path: String
    
    var body: some View {
        Button(action: {
            message = Git.status(path)
        }, label: {
            Label("检查", systemImage: "arrow.clockwise.circle")
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
