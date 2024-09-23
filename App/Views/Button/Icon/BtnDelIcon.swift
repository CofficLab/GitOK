import SwiftUI
import OSLog

struct BtnDelIcon: View {
    var icon: IconModel
    var callback: () -> Void
    
    var body: some View {
        Button(action: delete) {
            Label("删除「\(icon.title)」", systemImage: "trash")
        }
    }
    
    private func delete() {
        self.icon.delete()
        self.callback()
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
