import SwiftUI

struct BtnPwd: View {
    @Binding var message: String
    
    var body: some View {
        Button("PWD", action: {
            message = Shell.pwd()
        })
    }
}

#Preview {
    AppPreview()
}
