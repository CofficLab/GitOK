import SwiftUI
import MagicCore

struct BannerBackground: View {
    @Binding var banner: BannerData

    var body: some View {
        MagicBackgroundGroup(for:banner.backgroundId)
            .opacity(banner.opacity)
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity)
    }
}

#Preview("App") {
    RootView {
        ContentLayout()
    }
    .frame(height: 800)
    .frame(width: 800)
}

#Preview("App-2") {
    RootView {
        ContentLayout()
    }
    .frame(height: 1200)
    .frame(width: 800)
}
