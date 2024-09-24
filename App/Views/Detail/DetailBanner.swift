import SwiftUI

struct DetailBanner: View {
    @EnvironmentObject var app: AppProvider
    @EnvironmentObject var b: BannerProvider
    
    @State var banner: BannerModel = .empty

    var body: some View {
        VSplitView {
            BannerHome(banner: self.$banner)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            self.banner = b.banner
        }
        .onChange(of: b.banner, {
            self.banner = b.banner
        })
        .onChange(of: self.banner, {
            self.banner.save()
            b.setBanner(self.banner, reason: "OnChage")
        })
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
