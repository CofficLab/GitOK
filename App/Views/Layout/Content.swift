import OSLog
import SwiftData
import SwiftUI

struct Content: View, SuperThread, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @Environment(\.modelContext) private var modelContext

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: ActionTab = .Git
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var projectExists: Bool = true // 新增状态变量

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
                            DetailGit()
                        case .Banner:
                            DetailBanner()
                        case .Icon:
                            DetailIcon()
                        }

                        StatusBar()
                    }
                } else {
                    VStack {
                        Text("项目不存在")
                            .foregroundColor(.red)
                            .font(.headline)

                        if let project = g.project {
                            Button("删除") {
                                deleteItem(project)
                            }
                        }
                    }
                }
            }

            Message()
        }
        .onAppear {
            if app.sidebarVisibility == true {
                self.columnVisibility = .all
            }

            if app.sidebarVisibility == false {
                self.columnVisibility = .doubleColumn
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
            ToolbarItem(placement: .navigation) {
                ProjectPicker()
            }

            ToolbarItem(placement: .principal) {
                Picker("选择标签", selection: $tab) {
                    Text("Git").tag(ActionTab.Git)
                    Text("Banner").tag(ActionTab.Banner)
                    Text("Icon").tag(ActionTab.Icon)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }

            if let project = g.project, project.isExist() {
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

    private func deleteItem(_ project: Project) {
        let path = project.path
        withAnimation {
            modelContext.delete(project)
            self.emitGitProjectDeleted(path: path)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
