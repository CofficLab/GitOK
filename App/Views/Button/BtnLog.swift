import SwiftUI

struct BtnLog: View {
    @Binding var message: String

    var path: String
    var git = GitShell()

    var body: some View {
        Button("Log", action: {
            message = try! GitShell.log(path)
        })
    }
}

#Preview {
    AppPreview()
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
