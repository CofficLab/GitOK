import OSLog
import SwiftUI

struct BtnDelBanner: View {
    @EnvironmentObject var b: BannerProvider

    var banner: BannerModel

    var body: some View {
        TabBtn(title: "删除「\(banner.title)」", imageName: "trash", onTap: {
            delete()
        })
    }

    func delete() {
        self.b.removeBanner(banner)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
