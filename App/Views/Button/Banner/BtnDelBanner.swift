import SwiftUI
import OSLog

struct BtnDelBanner: View {
    var banner: BannerModel
    var callback: () -> Void
    
    var body: some View {
        Button(action: delete) {
            Label("删除「\(banner.title)」", systemImage: "trash")
        }
    }
    
    private func delete() {
        self.banner.delete()
        self.callback()
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
}
