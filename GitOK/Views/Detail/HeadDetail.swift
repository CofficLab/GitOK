import SwiftUI

struct HeadDetail: View {
    @EnvironmentObject var app: AppManager
    
    @State var message = ""
    @State var diff = ""
    @State var diffOfFile = ""
    @State var files: [File] = []
    @State var file: File?

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
                FileList(file: $file, files: files)
                
                GroupBox {
                    ScrollView {
                        Text(diffOfFile)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            refreshAll()
            EventManager().onCommitted(refreshFiles)
        }
        .onChange(of: project, refreshAll)
        .onChange(of: file, {
            if let f = file {
                self.diffOfFile = try! Git.diffOfFile(project.path, file: f)
            }
        })
    }
    
    func refreshAll() {
        self.refreshFiles()
        self.refreshStatus()
        self.diff = try! Git.diff(project.path)
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
