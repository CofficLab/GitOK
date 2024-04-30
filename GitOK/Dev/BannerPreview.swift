import SwiftUI

struct BannerPreview: View {
    var body: some View {
        RootView {
            Content()
        }
        .modelContainer(DBConfig.getContainer())

    }
}

#Preview {
    BannerPreview()
}
