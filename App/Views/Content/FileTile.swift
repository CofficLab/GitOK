import SwiftUI

struct FileTile: View {
    var file: File
    var commit: GitCommit
    
    @State var isPresented: Bool = false
    
    var body: some View {
        HStack {
            Text(file.name).font(.footnote)
            Spacer()
            image
        }
    }
    
    var image: some View {
        switch file.type {
        case .modified:
            Image(systemName: "square.and.pencil")
                .foregroundStyle(.yellow)
        case .add:
            Image(systemName: "plus.square")
                .foregroundStyle(.green)
        case .delete:
            Image(systemName: "trash.square")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
