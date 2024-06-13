import SwiftUI

struct FileTile: View {
    var file: File
    var selected: File
    var commit: GitCommit
    
    @State var isPresented: Bool = false
    
    var body: some View {
        HStack {
            Text(file.name)
            Spacer()
            image
        }.navigationDestination(isPresented: $isPresented, destination: {
            FileDetail(file: file, commit: commit)
        })
        .onAppear {
            ifPresented()
        }
        .onChange(of: selected, {
            ifPresented()
        })
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
    
    func ifPresented() {
        self.isPresented = file.id == selected.id
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
