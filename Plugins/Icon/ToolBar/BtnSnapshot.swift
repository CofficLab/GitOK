import SwiftUI
import MagicCore

struct BtnSnapshot: View {
    @EnvironmentObject var i: IconProvider

    var body: some View {
        TabBtn(
            title: "截图",
            imageName: "camera.aperture",
            selected: false,
            onTap: {
                i.snapshotTapped = true
            }
        )
    }
} 

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
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
