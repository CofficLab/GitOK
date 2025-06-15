import MagicCore
import OSLog
import SwiftUI

struct BannerDetail: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    var body: some View {
        BannerEditor(banner: $b.banner)
            .onChange(of: b.banner, {
                do {
                    try b.banner.saveToDisk()
                } catch {
                    m.error(error.localizedDescription)
                }
            })
    }
}

#Preview {
    RootView {
        BannerDetail()
    }
    .frame(height: 800)
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
