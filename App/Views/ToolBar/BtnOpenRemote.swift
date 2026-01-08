import SwiftUI
import OSLog


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
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
