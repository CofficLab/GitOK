import OSLog
import SwiftData
import SwiftUI

struct BannerList: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider

    @State var banner: BannerModel = .empty
    @State var banners: [BannerModel] = []

    var label: String { "🌹 BannerList::" }
    var verbose = true

    var body: some View {
        VStack(spacing: 0) {
            List(banners, selection: $banner) { banner in
                BannerTile(banner: banner, selected: self.banner) .contextMenu(ContextMenu(menuItems: {
                    BtnDelBanner(banner: banner, callback: getBanners)
                }))
                .tag(banner)
            }
            .frame(maxHeight: .infinity)

            // 操作
            if let project = g.project {
                HStack(spacing: 0) {
                    TabBtn(title: "新建 Banner", imageName: "plus.circle", onTap: {
                        self.banners.append(BannerModel.new(project))
                    })
                }
                .frame(height: 25)
                .labelStyle(.iconOnly)
            }
        }
        .onAppear(perform: getBanners)
        .onChange(of: g.project, getBanners)
    }

    func getBanners() {
        if verbose {
            os_log("\(label)GetBanners")
        }

        if let project = g.project {
            DispatchQueue.global().async {
                let banners = BannerModel.all(project.path)

                DispatchQueue.main.async {
                    self.banners = banners

                    
                        if !banners.contains(banner) {
                            self.banner = banners.first ?? .empty
                        }
                }
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
