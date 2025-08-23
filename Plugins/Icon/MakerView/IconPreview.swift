import MagicCore
import SwiftUI

struct IconPreview: View {
    let icon: IconModel
    let platform: String

    var body: some View {
        ZStack {
            // 背景
            icon.background
            
            // 图标
            icon.image
                .resizable()
                .scaledToFit()
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
