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
            MagicButton.simple(icon: .iconAdd, title: "新建") {
                b.createBanner(in: project)
            }
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
            .hideProjectActions()
            .hideTabPicker()
            .setInitialTab(BannerPlugin.label)
    }
    .frame(width: 800)
    .frame(height: 1000)
}
