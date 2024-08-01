import SwiftUI

struct BtnWhoami: View {
    @Binding var message: String
    
    var body: some View {
        Button("whoami", action: {
            message = Shell.whoami()
        })
    }
}

#Preview {
    AppPreview()
}
