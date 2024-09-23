import SwiftUI

struct BtnPwd: View {
    @Binding var message: String
    
    var shell = Shell()
    
    var body: some View {
        Button("PWD", action: {
            message = shell.pwd()
        })
    }
}

#Preview {
    AppPreview()
}
