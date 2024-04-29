import SwiftUI

struct FileList: View {
    @EnvironmentObject var app: AppManager
    
    var files: [File] = []

    var body: some View {
        List(files, id: \.self, selection: $app.file) {
            FileTile(file: $0)
        }
        .onAppear {
            app.file = files.first
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
