import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct NoProject: View, SuperThread, SuperEvent {
    @EnvironmentObject var g: DataProvider

    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Sidebar()
        } detail: {
            ZStack {
                GuideView(
                    systemImage: "folder.badge.questionmark",
                    title: NSLocalizedString("project_not_exist", bundle: .main, comment: "")
                )

                if let project = g.project {
                    VStack {
                        Spacer()
                        BtnDeleteProject(project: project)
                        Spacer().frame(height: 60)
                    }
                }
            }
        }
    }
}

#Preview {
    RootView {
        NoProject()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("Default-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
