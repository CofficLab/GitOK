import SwiftUI

struct FileList: View {
    @EnvironmentObject var app: AppManager
    
    @State var file: File? = nil
    
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
