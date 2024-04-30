import OSLog
import SwiftData
import SwiftUI

struct Content: View {
    @EnvironmentObject var app: AppManager

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: String = ""

    var project: Project? { app.project }

    var body: some View {
        NavigationSplitView {
            Projects()
        } content: {
            TabView(selection: $tab) {
                History()
                    .tag("history")
                    .tabItem({
                        Text("Git")
                    })
                BannerList()
                    .tag("banner")
                    .tabItem({
                        Text("Banner")
                    })
                IconList2()
                    .tag("icon")
                    .tabItem({
                        Text("Icon")
                    })
            }
            .frame(idealWidth: 300)
            .frame(minWidth: 50)
        } detail: {
            if tab == "banner" {
                BannerHome(banner: $app.banner)
            } else if tab == "icon" {
                IconHome(icon: $app.icon)
            } else {
                if project?.isNotGit ?? false {
                    NotGit()
                } else {
                    Detail()
                }
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
