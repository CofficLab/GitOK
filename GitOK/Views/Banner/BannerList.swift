import SwiftData
import SwiftUI

struct BannerList: View {
    @EnvironmentObject var app: AppManager

    @State var banner: BannerModel?
    @State var banners: [BannerModel] = []

    var body: some View {
        VStack {
            List(banners, id: \.self, selection: $banner) { banner in
                Text(banner.title)
            }
            .onAppear(perform: getBanners)

            Spacer()

            // 操作
            HStack {
                BtnAddBanner(callback: {
                    self.banners.append($0)
                })
            }
        }
        .onChange(of: banner) {
            app.banner = banner
        }
    }

    func getBanners() {
        if let project = app.project {
            DispatchQueue.global().async {
                let banners = BannerModel.getBannersFromProject(project.path)

                DispatchQueue.main.async {
                    self.banners = banners
                }
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
