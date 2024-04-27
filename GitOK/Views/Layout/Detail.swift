import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    @Binding var message: String

    var project: Project
    var log: GitCommit?
    @Binding var file: File?

    var body: some View {
        VStack {
            if file != nil {
                HeadDetail(file: $file, project: project)
            }
            
            if let log = log {
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
