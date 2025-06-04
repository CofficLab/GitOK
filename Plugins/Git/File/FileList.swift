import MagicCore
import OSLog
import SwiftUI

struct FileList: View, SuperThread, SuperLog {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var m: MessageProvider

    @State var files: [File] = []
    @State var isLoading = false

    @Binding var file: File?
    
    var commit: GitCommit

    var body: some View {
        ScrollViewReader { scrollProxy in
            List(files, id: \.self, selection: self.$file) {
                FileTile(file: $0, commit: commit)
                    .tag($0 as File?)
            }
            .task {
                self.refresh(scrollProxy)
            }
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

    func refresh(_ scrollProxy: ScrollViewProxy) {
        self.isLoading = true

        self.bg.async {
            let verbose = true
            if verbose {
                os_log("\(self.t)Refresh")
            }

            let files = commit.getFiles(reason: "FileList.Refresh")

            self.main.async {
                self.files = files
                self.isLoading = false
                self.file = self.files.first
            }
        }
    }
}

#Preview("Big Screen") {
    RootView {
        ContentView()
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
