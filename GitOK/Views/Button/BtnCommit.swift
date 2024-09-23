import SwiftUI

struct BtnCommit: View {
    @EnvironmentObject var app: AppProvider

    @State var working = false

    var path: String
    var commit: String
    var git = Git()

    var body: some View {
        Button(working ? "..." : "提交", action: commitAndPush)
            .disabled(working)
    }

    func commitAndPush() {
        self.working = true
        
        Task.detached(operation: {
            do {
                _ = try await git.commitAndPush(path, commit: commit, verbose: false)

                DispatchQueue.main.async {
                    EventManager().emitCommitted()
                    self.working = false
                }
            } catch let error {
                DispatchQueue.main.async {
                    app.alert("提交出错", info: error.localizedDescription)
                    self.working = false
                }
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 1000)
}
