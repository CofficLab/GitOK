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
    @State var projectExists: Bool = true // 新增状态变量

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
                    .disabled(!projectExists) // 禁止点击
                    .overlay(
                        Group {
                            if !projectExists {
                                Color.black.opacity(0.3)
                            }
                        }
                    )
                    .onChange(of: tab, {
                        app.setTab(tab)
                    })
                    .onAppear {
                        self.tab = app.currentTab
                    }
            } detail: {
                if projectExists {
                    VStack(spacing: 0) {
                        switch self.tab {
                        case .Git:
                            Detail()
                        case .Banner:
                            DetailBanner()
                        case .Icon:
                            DetailIcon()
                        }

                        StatusBar()
                    }
                } else {
                    Text("项目不存在")
                        .foregroundColor(.red)
                        .font(.headline)
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

            // 检查项目是否存在
            if let project = project {
                self.projectExists = FileManager.default.fileExists(atPath: project.path)
            } else {
                self.projectExists = false
            }
        }
        .onChange(of: self.columnVisibility, checkColumnVisibility)
        .onChange(of: g.project) {
            if let newProject = g.project {
                self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
            } else {
                self.projectExists = false
            }
        }
        .toolbar(content: {
            if let project = project, projectExists {
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
