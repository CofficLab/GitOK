import SwiftUI

struct BannerTile: View {
    @EnvironmentObject var b: BannerProvider

    @State var banner: BannerModel

    var body: some View {
        Text(banner.title)
            .onChange(of: b.banner, {
                if b.banner.id == self.banner.id {
                    self.banner = b.banner
                }
            })
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
