import OSLog
import SwiftData
import SwiftUI

struct Content: View {
    @EnvironmentObject var app: AppProvider

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: ActionTab = .Git
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic

    var project: Project? { app.project }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                Projects()
            } content: {
                Tabs(tab: $tab)
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
            } detail: {
                Detail()
            }
            
            Message()
        }
        .navigationTitle(project?.title ?? "")
        .onAppear {
            if app.sidebarVisibility == true {
                self.columnVisibility = .all
            }
            
            if app.sidebarVisibility == false {
                self.columnVisibility = .doubleColumn
            }
        }
        .onChange(of: self.columnVisibility, {
            print(self.columnVisibility)
            if columnVisibility == .doubleColumn {
                app.hideSidebar()
            } else if columnVisibility == .automatic || columnVisibility == .all {
                app.showSidebar()
            }
        })
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
    RootView {
        Content()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
