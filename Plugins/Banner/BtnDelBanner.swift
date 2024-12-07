import SwiftUI
import OSLog

struct BtnDelBanner: View {
    @EnvironmentObject var b: BannerProvider
    
    var banner: BannerModel
    
    var body: some View {
        Button(action: delete) {
            Label("删除「\(banner.title)」", systemImage: "trash")
        }
    }
    
    func delete() {
        self.b.removeBanner(banner)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
