import SwiftUI
import MagicCore

struct FileTile: View {
    var file: File
    var commit: GitCommit
    
    @State var isPresented: Bool = false
    
    var body: some View {
        HStack {
            image
            Text(file.name).font(.footnote)
            Spacer()
        }
    }
    
    var image: some View {
        switch file.type {
        case .modified:
            Image(systemName: "square.and.pencil")
        case .add:
            Image(systemName: "plus.square")
        case .delete:
            Image(systemName: "trash.square")
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}

#Preview("App-Big Screen") {
    RootView {
        ContentLayout()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
