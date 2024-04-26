import SwiftData
import SwiftUI
import OSLog

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
            }
        } detail: {
            if let project = project, let gitLog = gitLog {
                Detail(project, log: gitLog)
            }
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
                    BranchPicker(branch: $branch, project: project)
                })
            }
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
