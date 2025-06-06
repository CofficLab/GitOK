import MagicCore
import OSLog
import SwiftUI

struct ContentLayout: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State var projectExists: Bool = true
    @Binding var tab: String

    var statusBarVisibility: Bool

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Projects()
                .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 300)
                .toolbar(content: {
                    ToolbarItem {
                        BtnAdd()
                    }
                })
        } detail: {
            if self.projectExists == false {
                VStack {
                    GuideView(
                        systemImage: "folder.badge.questionmark",
                        title: "项目不存在"
                    )

                    if let project = g.project {
                        BtnDeleteProject(project: project)
                        Spacer().frame(height: 60)
                    }
                }
            } else {
                HSplitView {
                    VStack(spacing: 0) {
                        ForEach(p.plugins.filter { plugin in
                            plugin.addListView(tab: tab, project: g.project) != nil
                        }, id: \.instanceLabel) { plugin in
                            plugin.addListView(tab: tab, project: g.project)
                        }
                    }
                    .frame(idealWidth: 200)
                    .frame(minWidth: 120)
                    .frame(maxWidth: 200)

                    VStack(spacing: 0) {
                        p.tabPlugins.first { $0.instanceLabel == tab }?.addDetailView()

                        if statusBarVisibility {
                            StatusBar()
                        }
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
    }
}

extension ContentLayout {
    func checkIfProjectExists() {
        if let newProject = g.project {
            self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
        } else {
            self.projectExists = false
        }
    }
}

extension ContentLayout {
    func onAppear() {
        checkIfProjectExists()
    }

    /// 处理项目变更事件
    /// 当 GitProvider 中的项目发生变化时调用，检查项目是否存在并更新 UI
    func onProjectChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newProject = g.project {
                self.projectExists = FileManager.default.fileExists(atPath: newProject.path)
            } else {
                self.projectExists = false
            }
        }
    }
}
