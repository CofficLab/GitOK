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

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
