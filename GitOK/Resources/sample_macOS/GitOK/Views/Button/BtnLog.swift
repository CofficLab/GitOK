import SwiftUI

struct BtnLog: View {
    @Binding var message: String

    var path: String

    var body: some View {
        Button("Log", action: {
            message = Git.log(path)
        })
    }
}

#Preview {
    AppPreview()
}
