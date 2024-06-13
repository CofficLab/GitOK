import SwiftUI

struct GitDetail: View {
    @EnvironmentObject var app: AppManager
    
    var project: Project
    var commit: GitCommit

    var body: some View {
            if project.isNotGit {
                NotGit()
            } else {
                GeometryReader { geo in
                    if commit.getFiles().count == 0 {
                        VStack {
                            MergeForm().padding()
                            NoChanges().frame(maxHeight: .infinity)
                        }
                    } else {
                        VStack {
                            if commit.isHead {
                                CommitForm().padding()
                                MergeForm().padding()
                            }

                            DiffView(commit: commit)
                                    .frame(maxHeight: .infinity)
                        }
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
