import SwiftUI

struct BtnSave: View {
    @EnvironmentObject var app: AppProvider

    @Binding var message: String

    @State var working = false

    var path: String

    var commitMessage = CommitCategory.auto

    var body: some View {
        Button(action: save, label: {
            Label("保存", systemImage: "arrow.triangle.2.circlepath.icloud")
        }).disabled(working)
    }

    func save() {
        working = true

        AppConfig.bgQueue.async {
            do {
                try Git.add(path)
                message = try Git.commit(path, commit: commitMessage)
                message = try Git.push(path)

                AppConfig.mainQueue.async {
                    self.working = false
                }

                EventManager().emitCommitted()
            } catch let error {
                app.alert("保存出错", info: error.localizedDescription)
                AppConfig.mainQueue.async {
                    self.working = false
                }
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
