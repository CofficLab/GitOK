import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager
    @State var message = ""

    var item: Project
    var log: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.item = item
        self.log = log
    }

    var body: some View {
        VStack {
            if log.isHead {
                HeadDetail(item, log: log)
            } else {
                LogDetail(item, log: log)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            message = Git.status(item.path)
        }
        .background(BackgroundView.type1.opacity(0.3))
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
