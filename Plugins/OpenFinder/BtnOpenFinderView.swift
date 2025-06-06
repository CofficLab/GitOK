import SwiftUI

struct BtnOpenFinderView: View {
    @EnvironmentObject var g: DataProvider

    var body: some View {
        if let project = g.project {
            Button(action: {
                NSWorkspace.shared.open(project.url)
            }, label: {
                Label(
                    title: { Text("用Finder打开") },
                    icon: { Image(systemName: "folder") }
                )
            })
        }
    }
}