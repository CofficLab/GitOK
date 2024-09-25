import OSLog
import SwiftData
import SwiftUI

struct BannerList: View, SuperThread {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var g: GitProvider
    @EnvironmentObject var b: BannerProvider

    @State var banner: BannerModel = .empty
    @State var banners: [BannerModel] = []

    var label: String { "🌹 BannerList::" }
    var verbose = true

    var body: some View {
        VStack(spacing: 0) {
            List(banners, selection: $banner) { banner in
                BannerTile(banner: banner).contextMenu(ContextMenu(menuItems: {
                    BtnDelBanner(banner: banner, callback: getBanners)
                }))
                .tag(banner)
            }
            .frame(maxHeight: .infinity)
            .onChange(of: self.banner, {
                b.setBannerURL(URL(filePath: self.banner.path!))
            })

            // 操作
            if let project = g.project {
                HStack(spacing: 0) {
                    TabBtn(title: "新建 Banner", imageName: "plus.circle", onTap: {
                        do {
                            self.banners.append(try BannerModel.new(project))
                        } catch {
                            os_log(.error, "\(label)GetBanners error -> \(error)")
                            app.setError(error)
                        }
                    })
                }
                .frame(height: 25)
                .labelStyle(.iconOnly)
            }
        }
        .onAppear(perform: getBanners)
        .onChange(of: g.project, getBanners)
//        .onChange(of: b.banner, getBanners)
    }

    func getBanners() {
        let verbose = false
        if verbose {
            os_log("\(label)GetBanners")
        }

        if let project = g.project {
            self.bg.async {
                do {
                    let banners = try project.getBanners()

                    self.main.async {
                        self.banners = banners

                        if !banners.contains(banner) {
                            self.banner = banners.first ?? .empty
                        }
                    }
                } catch {
                    os_log(.error, "\(label)GetBanners error -> \(error)")
                    self.main.async {
                        app.setError(error)
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
