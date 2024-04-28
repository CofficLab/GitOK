import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    @Binding var message: String
    @Binding var file: File?

    var project: Project
    var commit: GitCommit?

    var body: some View {
        VStack {
            if commit?.isHead ?? false {
                CommitForm(message: $message, project: project)
            }
            
            if let commit = commit {
                CommitDetail(project, log: commit)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            message = try! Git.status(project.path)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
