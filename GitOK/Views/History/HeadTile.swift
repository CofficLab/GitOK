import CodeEditorView
import LanguageSupport
import Rearrange
import SwiftUI

struct HeadTile: View {
    @EnvironmentObject var app: AppManager

    @State var files: [File] = []
    @Binding var file: File?

    var project: Project

    var body: some View {
        VStack {
            if files.isEmpty {
                NoChanges()
            } else {
                FileList(file: $file, files: files)
            }
        }
        .onAppear {
            refresh()
            EventManager().onCommitted(refresh)
        }
    }
    
    func refresh() {
        files = try! Git.changedFile(project.path)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
