import OSLog
import SwiftUI

struct BannerTile: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var app: AppProvider

    @State var title: String = ""

    var banner: BannerModel

    var body: some View {
        Text(title)
            .onAppear(perform: {
                self.title = banner.title
            })
            .onNotification(.bannerTitleChanged, { notification in
                if let title = notification.userInfo?["title"] as? String, let id = notification.userInfo?["id"] as? String {
                    if id == banner.id {
                        self.title = title
                    }
                }
            })
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
