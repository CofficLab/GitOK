import SwiftUI

struct FileList: View {
    @EnvironmentObject var app: AppManager
    
    var files: [File] = []

    var body: some View {
        List(files, id: \.self) {
            FileTile(file: $0)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
