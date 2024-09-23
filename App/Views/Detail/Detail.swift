import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppProvider

    var body: some View {
        VSplitView {
            if let commit = app.commit {
                CommitDetail(commit: commit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: commit.isHead ? 150 : 60)
                    .layoutPriority(1)

                HSplitView {
                    FileList()
                        .frame(minWidth: 200)
                        .layoutPriority(2)
                    
                    ZStack {
                        if let file = app.file {
                            FileDetail(file: file, commit: commit)
                        } else {
                            Spacer()
                        }
                    }
                    .layoutPriority(3)
                }
                .layoutPriority(6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
