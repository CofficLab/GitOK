import MagicCore
import SwiftUI

struct FileTile: View {
    var file: GitDiffFile
    var onDiscardChanges: ((GitDiffFile) -> Void)?

    @State var isPresented: Bool = false

    var body: some View {
        HStack {
//            image
            Text(file.file)
                .font(.footnote)
                .foregroundStyle(getColor())
            Spacer()
        }
        .contextMenu {
            if let onDiscardChanges = onDiscardChanges {
                Button("Discard Changes") {
                    onDiscardChanges(file)
                }
            }
        }
    }

    var image: some View {
        switch file.changeType {
        case "M":
            Image(systemName: "square.and.pencil")
        case "A":
            Image(systemName: "plus.square")
        case "D":
            Image(systemName: "trash.square")
        default:
            Image(systemName: "trash.square")
        }
    }

    func getColor() -> Color {
        switch file.changeType {
        case "M":
            Color.orange
        case "A":
            Color.green
        case "D":
            Color.red
        default:
            Color.gray
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
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
