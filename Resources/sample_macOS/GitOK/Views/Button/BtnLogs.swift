import SwiftUI

struct BtnLogs: View {
    @Binding var logs: [GitCommit]
    
    var path: String
    
    var body: some View {
        Button("Log", action: {
            logs = Git.logs(path)
        })
    }
}

#Preview {
    AppPreview()
}
