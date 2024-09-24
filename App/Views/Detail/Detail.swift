import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    
    var commit: GitCommit

    var body: some View {
        VSplitView {
            if let commit = g.commit {
                HSplitView {
                    FileList()
                        .frame(minWidth: 200)
                        .layoutPriority(2)
                    
                    ZStack {
                        if let file = g.file {
                            FileDetail(file: file, commit: commit)
                        } else {
                            Spacer()
                        }
                    }
                    .layoutPriority(3)
                }
                .layoutPriority(6)
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("选择一个 Commit")
                        Spacer()
                    }
                    Spacer()
                }
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
