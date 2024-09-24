import SwiftUI
import OSLog
struct FileList: View, SuperThread, SuperLog {
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
                .task {
                    self.refresh(scrollProxy)
                }
                .onChange(of: file, {
                    g.file = file
                })
                .onChange(of: commit, {
                    refresh(scrollProxy)
                })
                .onChange(of: files, {
                    withAnimation {
                        // 在主线程中调用 scrollTo 方法
                        scrollProxy.scrollTo(self.file, anchor: .top)
                    }
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
            let verbose = false
            if verbose {
                os_log("\(self.t)Refresh")
            }

            let files = commit.getFiles(reason: "FileList.Refresh")

            DispatchQueue.main.async {
                self.files = files
                self.isLoading = false
                self.file = self.files.first
            }
        }
    }
}

#Preview {
    AppPreview()
}
