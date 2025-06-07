import SwiftUI

struct BtnLog: View {
    @Binding var message: String

    var path: String
    var git = GitShell()

    var body: some View {
        Button("Log", action: {
            message = try! GitShell.log(path)
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
