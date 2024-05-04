import SwiftData
import SwiftUI
import OSLog

struct BannerList: View {
    @EnvironmentObject var app: AppManager

    @State var banner: BannerModel? = nil
    @State var banners: [BannerModel] = []
    
    var label: String { "\(Logger.isMain)🌹 BannerList::"}
    var verbose = true

    var body: some View {
        VStack(spacing: 0) {
            List(banners, id: \.self, selection: $banner) { banner in
                Text(banner.title)
                    .tag(banner as BannerModel?)
                    .id(banner.id)
            }
            .frame(maxHeight: .infinity)

            // 操作
            if let project = app.project {
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
        .onChange(of: app.project, getBanners)
        .onChange(of: banner) {
            app.banner = banner
            getBanners()
        }
    }

    func getBanners() {
        if verbose {
            os_log("\(self.label)GetBanners")
        }
        
        if let project = app.project {
            DispatchQueue.global().async {
                let banners = BannerModel.all(project.path)

                DispatchQueue.main.async {
                    self.banners = banners
                    
                    if let banner = self.banner {
                        if !banners.contains(banner) {
                            self.banner = banners.first
                        }
                    } else {
                        self.banner = banners.first
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
