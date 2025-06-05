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

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
