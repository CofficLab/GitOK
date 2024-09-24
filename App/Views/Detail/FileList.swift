import SwiftUI

struct FileList: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var files: [File] = []
    @State var file: File?
    @State var isLoading = false

    var commit: GitCommit? {
        g.commit
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
                    self.g.file = self.files.first
                }
                .onChange(of: file, {
                    g.file = file
                })
                .onChange(of: commit, {
                    refresh(scrollProxy)
                })
                .background(.blue)
            }
        }
    }

    func refresh(_ scrollProxy: ScrollViewProxy) {
        guard let commit = commit else {
            return
        }

        self.isLoading = true

        self.bg.async {
            let files = commit.getFiles()

            self.main.async {
                self.files = files
                self.isLoading = false

                withAnimation {
                    scrollProxy.scrollTo(1, anchor: .top)
                }
            }
        }
    }
}

#Preview {
    AppPreview()
}
