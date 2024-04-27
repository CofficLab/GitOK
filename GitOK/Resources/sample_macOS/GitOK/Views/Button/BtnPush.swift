import SwiftUI

struct BtnPush: View {
    @Binding var message: String
    
    var path: String
    
    var body: some View {
        Button("推送", action: {
            message = Git.push(path)
        })
    }
}

#Preview {
    AppPreview()
}
