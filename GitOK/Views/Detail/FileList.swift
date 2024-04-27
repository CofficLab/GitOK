import SwiftUI

struct FileList: View {
    @EnvironmentObject var app: AppManager
    
    @Binding var file: File?
    
    var files: [File] = []

    var body: some View {
        List(files, id: \.self, selection: $file) {
            FileTile(file: $0)
        }
        .onAppear {
            self.file = files.first
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
