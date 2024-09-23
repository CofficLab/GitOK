import SwiftUI

struct CommitDetail: View {
    var commit: GitCommit

    var body: some View {
        if commit.isHead {
            if commit.getFiles().isEmpty {
                Text("本地无变动")
            } else {
                VStack {
                    CommitForm().padding(.vertical)
                    MergeForm()
                }
                .padding()
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 600)
}
