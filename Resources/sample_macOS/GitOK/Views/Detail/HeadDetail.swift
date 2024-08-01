import SwiftUI

struct HeadDetail: View {
    @EnvironmentObject var app: AppManager
    @State var message = ""
    @State var files: [File] = []

    var project: Project
    var log: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.project = item
        self.log = log
    }

    var body: some View {
        VStack {
            CommitForm(message: $message, project: project)
            
            Spacer()

            if files.isEmpty {
                GroupBox {
                    Text(message)
                }
            } else {
                FileList(files: files)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            refreshFiles()
            EventManager().onCommitted(refreshFiles)
        }
        .onChange(of: log, refreshStatus)
    }
    
    func refreshFiles() {
        files = Git.changedFile(project.path)
        
        if files.isEmpty {
            refreshStatus()
        }
    }
    
    func refreshStatus() {
        message = Git.status(project.path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
