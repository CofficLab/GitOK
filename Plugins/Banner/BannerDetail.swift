import OSLog
import SwiftUI

struct BannerDetail: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        BannerEditor(banner: $b.banner)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .onChange(of: b.banner, {
            do {
                try b.banner.saveToDisk()
            } catch {
                m.setError(error)
            }
        })
    }
}

#Preview {
    RootView {
        BannerDetail()
    }
    .frame(height: 800)
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
