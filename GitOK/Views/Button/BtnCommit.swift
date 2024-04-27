import SwiftUI

struct BtnCommit: View {
    @EnvironmentObject var app: AppManager
    @Binding var message: String

    var path: String
    var commit: String

    var body: some View {
        Button("提交", action: commitAndPush)
    }
    
    func commitAndPush() {
        do {
            try message = Git.commit(path, commit: commit)
            message = try Git.push(path)
            
            EventManager().emitCommitted()
        } catch let error {
            app.alert("提交出错", info: error.localizedDescription)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
