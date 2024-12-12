import SwiftUI

struct BtnLogs: View {
    @Binding var logs: [GitCommit]
    
    var path: String
    
    var body: some View {
        Button("Log", action: {
            logs = try! GitShell.logs(path)
        })
    }
}

#Preview {
    AppPreview()
}
