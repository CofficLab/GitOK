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
    @State var file: File?

    var body: some View {
        NavigationSplitView {
            Projects(project: $project)
        } content: {
            if let project = project, let branch = branch {
                History(selection: $gitLog, file: $file, project: project, branch: branch)
                    .frame(idealWidth: 300)
                    .frame(minWidth: 50)
            }
        } detail: {
            VSplitView {
                if let project = project {
                    Detail(message: $message, file: $file, project: project, commit: gitLog)
                }
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
