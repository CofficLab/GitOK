import MagicCore
import OSLog
import SwiftData
import SwiftUI

struct BannerList: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var selection: BannerModel.ID?

    var body: some View {
        VStack(spacing: 0) {
            List(b.banners, selection: $selection) { banner in
                BannerTile(banner: banner).tag(banner)
            }
            .frame(maxHeight: .infinity)

            HStack() {
                BannerBtnAdd()
                BtnDelBanner(banner: b.banner)
            }
            .frame(height: 25)
            .labelStyle(.iconOnly)
        }
        .onAppear(perform: onAppear)
        .onChange(of: g.project, onProjectChange)
        .onChange(of: selection, onSelectionChange)
        .onChange(of: b.banner, onBannerChange)
    }

    func getBanners() {
        if let project = g.project {
            b.setBanners(project)
        }
    }
}

extension BannerList {
    func onBannerChange() {
        self.selection = b.banner.id
    }

    func onProjectChange() {
        getBanners()
    }

    func onAppear() {
        getBanners()
    }

    func onSelectionChange() {
        b.setBanner(b.banners.first(where: { $0.id == selection }) ?? .empty)
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
