import MagicKit
import OSLog
import SwiftData
import SwiftUI

struct ContentView: View, SuperThread, SuperEvent {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var p: PluginProvider
    @Environment(\.modelContext) private var modelContext

    @State var branch: Branch? = nil
    @State var gitLog: String? = nil
    @State var message: String = ""
    @State var tab: String = "Git"
    @State var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State var projectExists: Bool = true

    var tabPlugins: [SuperPlugin] {
        p.plugins.filter { $0.isTab }
    }

    var body: some View {
        Group {
            if projectExists {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    Sidebar()
                } content: {
                    if projectExists {
                        Tabs(tab: $tab)
                            .frame(idealWidth: 300)
                            .frame(minWidth: 50)
                            .onChange(of: tab, onChangeOfTab)
                    }
                } detail: {
                    VStack(spacing: 0) {
                        tabPlugins.first { $0.label == tab }?.addDetailView()

                        StatusBar()
                    }
                }
            } else {
                NoProject()
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: columnVisibility, onCheckColumnVisibility)
        .toolbar(content: {
            ToolbarItem(placement: .navigation) {
                ProjectPicker()
            }

            ToolbarItem(placement: .principal) {
                Picker("选择标签", selection: $tab) {
                    ForEach(tabPlugins, id: \.label) { plugin in
                        Text(plugin.label).tag(plugin.label)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }

            if let project = g.project, project.isExist() {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    BtnOpenTerminal(url: project.url)
                    BtnOpenXcode(url: project.url)
                    BtnOpen(url: project.url)
                    BtnOpenCursor(url: project.url)
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
}

// MARK: Event Handlers

extension ContentView {
    func onProjectChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newProject = g.project {
                self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
            } else {
                self.projectExists = false
            }
        }
    }

    func onAppear() {
        if app.sidebarVisibility == true {
            self.columnVisibility = .all
        }

        if app.sidebarVisibility == false {
            self.columnVisibility = .doubleColumn
        }

        self.tab = app.currentTab
    }

    func onCheckColumnVisibility() {
        self.main.async {
            if columnVisibility == .doubleColumn {
                app.hideSidebar()
            } else if columnVisibility == .automatic || columnVisibility == .all {
                app.showSidebar()
            }
        }
    }

    func onChangeOfTab() {
        app.setTab(tab)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
