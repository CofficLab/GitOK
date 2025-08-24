import SwiftUI
import MagicCore

struct IconListActions: View {
    var body: some View {
        HStack(spacing: 0) {
            BtnNewIcon()
        }
        .frame(height: 25)
        .labelStyle(.iconOnly)
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
