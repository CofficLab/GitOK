import SwiftUI

struct BtnOpenRemoteView: View {
    @EnvironmentObject var g: DataProvider
    @State var remote: String = ""

    var body: some View {
        if let project = g.project {
            Button(action: {
                remote = GitShell.getRemote(project.path).trimmingCharacters(in: .whitespacesAndNewlines)

                if remote.hasPrefix("git@") {
                    remote = remote.replacingOccurrences(of: ":", with: "/")
                    remote = remote.replacingOccurrences(of: "git@", with: "https://")
                }

                if let url = URL(string: remote) {
                    NSWorkspace.shared.open(url)
                }
            }, label: {
                Label(
                    title: { Text("打开远程仓库") },
                    icon: { Image(systemName: "safari") }
                )
            })
        }
    }
}