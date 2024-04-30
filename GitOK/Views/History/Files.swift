import OSLog
import SwiftUI

struct Files: View {
    @EnvironmentObject var app: AppManager

    @State var files: [File] = []
    @State var loading = false

    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }
    var verbose = true
    var label: String { "\(Logger.isMain)🖥️ Files::" }

    var body: some View {
        ZStack {
            if loading {
                Text("loading...")
            } else {
                if app.project != nil {
                    VStack {
                        if files.count > 0 {
                            List(files, id: \.self, selection: $app.file) {
                                FileTile(file: $0)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if verbose {
                os_log("\(self.label)Refresh because of: onAppear")
            }
            
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
        .onChange(of: project?.id) {
            os_log("\(self.label)Project Changed, Refresh")
            refresh()
        }
    }

    func refresh() {
        guard let commit = app.commit else {
            return
        }

        self.loading = true
        
        DispatchQueue.global().async {
            let files = commit.getFiles()
            let file = files.first
            
            DispatchQueue.main.async {
                self.files = files
                app.file = file
                self.loading = false
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
