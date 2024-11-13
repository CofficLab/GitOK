import MagicKit
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
    @State var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State var projectExists: Bool = true

    var body: some View {
        Group {
            ZStack {
                if projectExists {
                    hasProjectView
                } else {
                    NoProject()
                }
                
                Message()
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: self.columnVisibility, checkColumnVisibility)
        .onChange(of: g.project, onProjectChange)
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

    var hasProjectView: some View {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                Sidebar()
            } content: {
                if projectExists {
                    Tabs(tab: $tab)
                        .frame(idealWidth: 300)
                        .frame(minWidth: 50)
                        .onChange(of: tab, {
                            app.setTab(tab)
                        })
                        .onAppear {
                            self.tab = app.currentTab
                        }
                }
            } detail: {
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
            }
    }
}

// MARK: Event Handlers

extension Content {
    func onProjectChange() {
        if let newProject = g.project {
            self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
        } else {
            self.projectExists = false
        }
    }
    
    func onAppear() {
        if app.sidebarVisibility == true {
            self.columnVisibility = .all
        }

        if app.sidebarVisibility == false {
            self.columnVisibility = .doubleColumn
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
