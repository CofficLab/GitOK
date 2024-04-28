import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager
    
    @State var files: [File] = []
    @State var file: File? = nil

    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }

    var body: some View {
        if let project = project {
            VStack {
                if commit?.isHead ?? false {
                    CommitForm()
                }
                
                if let commit = commit {
                    VStack {
                        List(files, id: \.self, selection: $file) {
                            FileTile(file: $0)
                        }
                        .onAppear {
                            self.file = files.first
                        }
                        
                        if let file = file {
                            DiffView(file)
                                .frame(maxHeight: .infinity)
                        }

                        if files.isEmpty {
                            Text("本地无变动")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                refresh()

                EventManager().onCommitted {
                    refresh()
                }
            }
            .onChange(of: commit, refresh)
        }
    }
    
    func refresh() {
        guard let commit = commit else {
            return
        }
        files = commit.getFiles()
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
