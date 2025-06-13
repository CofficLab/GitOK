import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct BannerBtnAdd: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        if let project = g.project {
            TabBtn(title: "新建 Banner", imageName: "plus.circle", onTap: {
                b.appendBanner(BannerModel.new(project))
            })
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
