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
