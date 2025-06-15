import SwiftUI
import OSLog
import MagicCore

struct BtnOpenRemote: View {
    @EnvironmentObject var g: DataProvider
    
    @Binding var message: String

    @State var remote: String = ""

    var path: String

    var body: some View {
//        Button(action: {
//            remote = try ShellGit.firstRemoteURL(at: path)!
//
//            if remote.hasPrefix("git@") {
//                remote = remote.replacingOccurrences(of: ":", with: "/")
//                remote = remote.replacingOccurrences(of: "git@", with: "https://")
//            }
//
//            if let url = URL(string: remote) {
//                NSWorkspace.shared.open(url)
//            }
//        }, label: {
//            Label(
//                title: { Text("打开远程仓库") },
//                icon: { Image(systemName: "safari") }
//            )
//        })
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
