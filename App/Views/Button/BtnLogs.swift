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

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
