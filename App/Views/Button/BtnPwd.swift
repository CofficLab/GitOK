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

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
