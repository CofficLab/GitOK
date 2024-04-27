import OSLog
import SwiftData
import SwiftUI

struct Content: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var app: AppManager

    @State var project: Project? = nil
    @State var branch: Branch? = nil
    @State var gitLog: GitCommit? = nil
    @State var message: String = ""

    var body: some View {
        NavigationSplitView {
            Projects(project: $project)
        } content: {
            if let project = project, let branch = branch {
                History(selection: $gitLog, item: project, branch: branch)
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
            }
        } detail: {
            VSplitView {
                if let project = project, let gitLog = gitLog {
                    Detail(message: $message, project: project, log: gitLog)
                }

                ScrollView {
                    Text(message)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(project?.title ?? "")
        .toolbar(content: {
            if let project = project {
                ToolbarItemGroup(placement: .cancellationAction, content: {
                    BtnStatus(message: $message, path: project.path)
                    BtnOpenXcode(url: project.url)
                    BtnOpen(url: project.url)
                    BtnFinder(url: project.url)
                    BtnOpenRemote(message: $message, path: project.path)
                    BtnSave(message: $message, path: project.path)
                    Branchs(branch: $branch, message: $message, project: project)
                })
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
