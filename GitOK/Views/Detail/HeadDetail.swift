import SwiftUI

struct HeadDetail: View {
    @EnvironmentObject var app: AppManager
    @State var message = ""
    @State var files: [File] = []

    var project: Project

    init(_ item: Project) {
        self.project = item
    }

    var body: some View {
        VStack {
            MergeForm(message: $message, project: project)
            
            CommitForm(message: $message, project: project)
            
            Spacer()

            if files.isEmpty {
                NoChanges()
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
        .onChange(of: project, refreshAll)
    }
    
    func refreshAll() {
        self.refreshFiles()
        self.refreshStatus()
    }
    
    func refreshFiles() {
        files = try! Git.changedFile(project.path)
        
        if files.isEmpty {
            refreshStatus()
        }
    }
    
    func refreshStatus() {
        message = try! Git.status(project.path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
