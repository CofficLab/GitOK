import SwiftUI

struct CommitDetail: View {
    @EnvironmentObject var app: AppManager
    
    @State var message = ""
    @State var files: [File] = []
    @State var file: File? = nil

    var item: Project
    var commit: GitCommit

    init(_ item: Project, log: GitCommit) {
        self.item = item
        self.commit = log
    }

    var body: some View {
        GeometryReader { geo in
        VStack {
                List(files, id: \.self, selection: $file) {
                    FileTile(file: $0)
                }
                .frame(maxHeight: geo.size.height/2)
                .onAppear {
                    self.file = files.first
                }
                
                DiffView(file)
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear {
            files = commit.getFiles()
        }
        .onChange(of: commit.hash, {
            files = commit.getFiles()
        })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
