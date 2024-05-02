import OSLog
import SwiftData
import SwiftUI

struct Content: View {
    @EnvironmentObject var app: AppManager

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: ActionTab = .Git

    var project: Project? { app.project }

    var body: some View {
        NavigationSplitView {
            Projects()
        } content: {
            Tabs(tab: $tab)
                .frame(idealWidth: 300)
                .frame(minWidth: 50)
        } detail: {
            Detail(tab: $tab)
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
                    if project.isGit {
                        Branches()
                    }
                })
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
