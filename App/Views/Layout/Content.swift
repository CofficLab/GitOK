import OSLog
import SwiftData
import SwiftUI

struct Content: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: ActionTab = .Git
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic

    var project: Project? { g.project }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                Projects()
                    .toolbar(content: {
                        ToolbarItem {
                            BtnAdd()
                        }
                    })
            } content: {
                Tabs(tab: $tab)
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
            } detail: {
                switch self.tab {
                case .Git:
                    VStack(spacing: 0) {
                        Detail()
                        StatusBar()
                    }
                case .Banner:
                    Text("Banner")
                case .Icon:
                    Text("icon")
                }
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
        .onChange(of: self.columnVisibility, checkColumnVisibility)
        .toolbar(content: {
            if let project = project {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    BtnOpenTerminal(url: project.url)
                    BtnOpenXcode(url: project.url)
                    BtnOpen(url: project.url)
                    BtnFinder(url: project.url)
                    BtnOpenRemote(message: $message, path: project.path)
                    BtnSync(message: $message, path: project.path)
                    if project.isGit {
                        Branches()
                    }
                })
            }
        })
    }

    func checkColumnVisibility() {
        self.main.async {
            if columnVisibility == .doubleColumn {
                app.hideSidebar()
            } else if columnVisibility == .automatic || columnVisibility == .all {
                app.showSidebar()
            }
        }
    }
}

#Preview {
    RootView {
        Content()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
