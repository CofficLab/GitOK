import OSLog
import SwiftData
import SwiftUI

struct Content: View {
    @EnvironmentObject var app: AppManager

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""

    var project: Project? { app.project }

    var body: some View {
        NavigationSplitView {
            Projects()
        } content: {
            TabView {
                History()
                    .tabItem({
                        Text("Git")
                    })
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
                #if DEBUG
                History()
                    .tabItem({
                        Text("Icon")
                    })
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
                History()
                    .tabItem({
                        Text("Banner")
                    })
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
                #endif
            }
        } detail: {
            if project?.isNotGit ?? false {
                NotGit()
            } else {
                Detail()
            }
        }
        .navigationTitle(project?.title ?? "")
        .toolbar(content: {
            if let project = project {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    BtnRefresh(message: $message, path: project.path)
                    BtnOpenTerminal(url: project.url)
                    BtnOpenXcode(url: project.url)
                    BtnOpen(url: project.url)
                    BtnFinder(url: project.url)
                    BtnOpenRemote(message: $message, path: project.path)
                    BtnSave(message: $message, path: project.path)
                    Branches()
                })
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
