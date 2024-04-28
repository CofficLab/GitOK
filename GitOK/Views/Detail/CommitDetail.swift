import SwiftUI

struct CommitDetail: View {
    @EnvironmentObject var app: AppManager
    
    @State var message = ""
    @State var files: [File] = []
    @State var file: File? = nil

    var item: Project
    var commit: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.item = item
        self.commit = log
    }

    var body: some View {
        VStack {
            FileList(file: $file, files: files)
        }
        .onAppear {
            files = try! Git.commitFiles(item.path, hash: commit.hash)
        }
        .onChange(of: commit.hash, {
            files = try! Git.commitFiles(item.path, hash: commit.hash)
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
