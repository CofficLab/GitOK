import MagicCore
import SwiftUI

struct FileTile: View {
    var file: File

    @State var isPresented: Bool = false

    var body: some View {
        HStack {
//            image
            Text(file.name)
                .font(.footnote)
                .foregroundStyle(getColor())
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

    func getColor() -> Color {
        switch file.type {
        case .modified:
            Color.orange
        case .add:
            Color.green
        case .delete:
            Color.red
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
