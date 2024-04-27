import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager
    
    @Binding var message: String

    var project: Project
    var log: GitCommit

    var body: some View {
        VStack {
            if log.isHead {
                HeadDetail(project)
            } else {
                CommitDetail(project, log: log)
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
