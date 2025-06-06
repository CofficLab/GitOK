import MagicCore
import OSLog
import SwiftUI

struct NotExists: View, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var p: PluginProvider

    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    @Binding var tab: String

    var statusBarVisibility: Bool
    var projectExists: Bool

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
        }
    }
}
