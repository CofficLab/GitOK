import SwiftUI

struct BtnLogs: View {
    @Binding var logs: [GitCommit]
    
    var path: String
    var git = GitShell()
    
    var body: some View {
        Button("Log", action: {
            logs = try! git.logs(path)
        })
    }
}

#Preview {
    AppPreview()
}
