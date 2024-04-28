import SwiftUI

struct Detail: View {
    @EnvironmentObject var app: AppManager

    @State var files: [File] = []
    @State var file: File? = nil

    var project: Project? { app.project }
    var commit: GitCommit? { app.commit }

    var body: some View {
        GeometryReader { geo in
            VStack {
                if files.isEmpty {
                    NoChanges()
                } else {
                    if commit?.isHead ?? false {
                        CommitForm().padding()
                    }

                    List(files, id: \.self, selection: $file) {
                        FileTile(file: $0)
                    }
                    
                    if let file = file {
                        DiffView(file)
                            .frame(maxWidth: .infinity)
                            .frame(height: geo.size.height * 0.7)
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

            EventManager().onRefresh {
                refresh()
            }
        }
        .onChange(of: commit, refresh)
    }

    func refresh() {
        guard let commit = commit else {
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
