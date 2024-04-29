import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }

    var body: some View {
        GeometryReader { geo in
            if commit?.getFiles().count == 0 {
                NoChanges()
            } else {
                VStack {
                    if commit?.isHead ?? false {
                        CommitForm().padding()
                        MergeForm().padding()
                    }

                    DiffView()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
