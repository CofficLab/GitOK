import SwiftUI

struct FileList: View {
    @EnvironmentObject var app: AppProvider

    @State var files: [File] = []
    @State var file: File?

    var commit: GitCommit? {
        app.commit
    }

    var body: some View {
        if let commit = commit {
            ScrollViewReader { scrollProxy in
                List(files, id: \.self, selection: self.$file) {
                    FileTile(file: $0, commit: commit)
                        .tag($0 as File?)
                }
                .onAppear {
                    self.files = commit.getFiles()
                    self.app.file = self.files.first
                }
                .onChange(of: file, {
                    app.file = file
                })
                .onChange(of: commit, {
                    self.files = commit.getFiles()
                    self.app.file = self.files.first
                    withAnimation {
                        scrollProxy.scrollTo(1, anchor: .top)
                    }
                })
                .background(.blue)
            }
        }
    }
}

#Preview {
    AppPreview()
}
