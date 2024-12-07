import OSLog
import SwiftUI

struct BannerDetail: View {
    @EnvironmentObject var b: BannerProvider

    var body: some View {
        VSplitView {
            BannerHome(banner: $b.banner)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
