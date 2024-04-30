import SwiftData
import SwiftUI

struct BannerList: View {
    @EnvironmentObject var app: AppManager

    @State var banner: BannerModel2?
    @State var banners: [BannerModel2] = []

    var body: some View {
        VStack {
            List(banners, id: \.self, selection: $banner) { banner in
                Text(banner.title)
            }
            
            Spacer()
            
            // 操作
            HStack {
                BtnAddBanner2(callback: {
                    self.banners.append($0)
                })
            }
        }
        .onChange(of: banner) {
            app.banner = banner
        }
        .onAppear {
            if let project = app.project {
                self.banners = BannerModel2.getBannersFromProject(project.path)
            }
        }
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
