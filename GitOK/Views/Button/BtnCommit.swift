import SwiftUI

struct BtnCommit: View {
    @Binding var message: String

    var path: String
    var commit: String

    var body: some View {
        Button("提交", action: {
            message = Git.commit(path, commit: commit)
            message = Git.push(path)
            
            EventManager().emitCommitted()
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
