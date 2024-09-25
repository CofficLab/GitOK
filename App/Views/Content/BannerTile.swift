import SwiftUI
import OSLog

struct BannerTile: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var app: AppProvider

    @State var title: String = ""

    var banner: BannerModel

    var body: some View {
        Text(title)
            .onAppear(perform: {
                self.title = banner.title
            })
            .onReceive(NotificationCenter.default.publisher(for: .bannerTitleChanged)) { notification in
                if let title = notification.userInfo?["title"] as? String, let id = notification.userInfo?["id"] as? String {
                    if id == banner.id {
                        self.title = title
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
