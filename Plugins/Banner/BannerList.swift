import MagicKit
import OSLog
import SwiftData
import SwiftUI

struct BannerList: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MessageProvider

    @State var selection: BannerModel?

    var label: String { "🌹 BannerList::" }
    var verbose = true

    var body: some View {
        VStack(spacing: 0) {
            List(b.banners, selection: $selection) { banner in
                BannerTile(banner: banner).contextMenu(ContextMenu(menuItems: {
                    BtnDelBanner(banner: banner, callback: getBanners)
                }))
                .tag(banner)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: selection, {
                b.setBanner(selection ?? .empty)
            })

            BannerListBar()
        }
        .onAppear(perform: getBanners)
        .onChange(of: g.project, onProjectChange)
    }

    func getBanners() {
        if let project = g.project {
            b.setBanners(project)
        }
    }

    func onProjectChange() {
        getBanners()
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
