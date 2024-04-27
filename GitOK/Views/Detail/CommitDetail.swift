import SwiftUI

struct CommitDetail: View {
    @EnvironmentObject var app: AppManager
    
    @State var message = ""
    @State var commitInfo: String = ""
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
            GroupBox {
                Text(commitInfo)
            }
            
            FileList(files: files)
        }
        .onAppear {
            commitInfo = try! Git.show(item.path, hash: commit.hash)
            files = try! Git.commitFiles(item.path, hash: commit.hash)
        }
        .onChange(of: commit.hash, {
            commitInfo = try! Git.show(item.path, hash: commit.hash)
            files = try! Git.commitFiles(item.path, hash: commit.hash)
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
