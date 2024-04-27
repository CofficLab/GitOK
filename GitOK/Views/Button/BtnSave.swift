import SwiftUI

struct BtnSave: View {
    @EnvironmentObject var app: AppManager
    @Binding var message: String

    @State var working = false

    var path: String

    var commitMessage: String = "\(CommitCategory.Chore.text): Auto Committed by GitOK"

    var body: some View {
        Button(action: save, label: {
            Label("保存", systemImage: "arrow.triangle.2.circlepath.icloud")
        }).disabled(working)
    }

    func save() {
        working = true

        do {
            message = try Git.commit(path, commit: GitCommit.autoCommitMessage)
            message = try Git.push(path)
            message = try Git.status(path)

            DispatchQueue.main.async {
                self.working = false
            }

            EventManager().emitCommitted()
        } catch let error {
            app.alert("保存出错", info: error.localizedDescription)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
