import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager
    @State var message = ""

    var project: Project
    var log: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.project = item
        self.log = log
    }

    var body: some View {
        VStack {
            if log.isHead {
                HeadDetail(project)
            } else {
                LogDetail(project, log: log)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            message = try! Git.status(project.path)
        }
        .background(BackgroundView.type1.opacity(0.3))
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
