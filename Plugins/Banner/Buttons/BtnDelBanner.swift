import OSLog
import SwiftUI

struct BtnDelBanner: View {
    @EnvironmentObject var b: BannerProvider

    var banner: BannerData

    var body: some View {
        TabBtn(title: "删除「\(banner.title)」", imageName: "trash", onTap: {
            delete()
        })
    }

    func delete() {
        self.b.removeBanner(banner)
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
