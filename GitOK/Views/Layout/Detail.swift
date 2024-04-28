import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }

    var body: some View {
        if let project = project {
            VStack {
                if commit?.isHead ?? false {
                    CommitForm()
                }
                
                if let commit = commit {
                    CommitDetail(project, log: commit)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
