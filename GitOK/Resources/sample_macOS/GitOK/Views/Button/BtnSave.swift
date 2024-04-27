import SwiftUI

struct BtnSave: View {
    @Binding var message: String
    
    @State var working = false
    
    var path: String
    
    var commitMessage: String = "\(CommitCategory.Chore.text): Auto Committed by GitOK"
    
    var body: some View {
        Button(action: {
            self.working = true
            Task.detached {
                message = Git.commit(path, commit: GitCommit.autoCommitMessage)
                message = Git.push(path)
                message = Git.status(path)
                
                DispatchQueue.main.async {
                    self.working = false
                }
                
                EventManager().emitCommitted()
            }
        }, label: {
            Label("保存", systemImage: "arrow.triangle.2.circlepath.icloud")
        }).disabled(working)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
