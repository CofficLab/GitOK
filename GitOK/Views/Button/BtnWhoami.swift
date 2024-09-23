import SwiftUI

struct BtnWhoami: View {
    @Binding var message: String
    
    var shell = Shell()
    
    var body: some View {
        Button("whoami", action: {
            message = shell.whoami()
        })
    }
}

#Preview {
    AppPreview()
}
