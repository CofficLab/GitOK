import OSLog
import SwiftUI

struct Files: View {
    @EnvironmentObject var app: AppManager

    @State var file: File? = nil {
        didSet {
            app.file = file
        }
    }

    @State var files: [File] = []

    var commit: GitCommit? { app.commit }
    var verbose = true
    var label = "🖥️ Files::"

    var body: some View {
        if app.project != nil {
            VStack {
                if files.count > 0 {
                    List(files, id: \.self, selection: $file) {
                        FileTile(file: $0)
                    }
                }
            }
            .onAppear {
                refresh()

                EventManager().onCommitted {
                    if verbose {
                        os_log("\(self.label)Refresh because of: Committed")
                    }

                    refresh()
                }

                EventManager().onRefresh {
                    refresh()
                }
            }
            .onChange(of: commit?.id) {
                os_log("\(self.label)Commit Changed, Refresh")
                refresh()
            }
        }
    }

    @MainActor
    func refresh() {
        guard let commit = app.commit else {
            return
        }

        files = commit.getFiles()
        file = files.first
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
