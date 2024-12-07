import OSLog
import SwiftUI

struct BannerDetail: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        VSplitView {
            BannerHome(banner: $b.banner)
        }
        .frame(maxWidth: .infinity)
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
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
