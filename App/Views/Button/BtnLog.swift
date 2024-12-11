import SwiftUI

struct BtnLog: View {
    @Binding var message: String

    var path: String
    var git = GitShell()

    var body: some View {
        Button("Log", action: {
            message = try! git.log(path)
        })
    }
}

#Preview {
    AppPreview()
}
