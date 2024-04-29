import SwiftUI

struct BtnCommit: View {
    @EnvironmentObject var app: AppManager

    @State var working = false

    var path: String
    var commit: String

    var body: some View {
        Button(working ? "..." : "提交", action: commitAndPush)
            .disabled(working)
    }

    func commitAndPush() {
        Task.detached(operation: {
            do {
                _ = try await Git.commitAndPush(path, commit: commit, verbose: true)

                DispatchQueue.main.async {
                    EventManager().emitCommitted()
                }
            } catch let error {
                DispatchQueue.main.async {
                    app.alert("提交出错", info: error.localizedDescription)
                }
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
