import SwiftUI

struct BtnOpenRemote: View {
    @Binding var message: String

    @State var remote: String = ""

    var path: String

    var body: some View {
        Button(action: {
            remote = Git.getRemote(path)

            if let url = URL(string: remote) {
                NSWorkspace.shared.open(url)
            }
        }, label: {
            Label(
                title: { Text("打开远程仓库") },
                icon: { Image(systemName: "safari") }
            )
        })
    }
}

#Preview {
    AppPreview()
}
