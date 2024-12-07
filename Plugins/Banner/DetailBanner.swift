import SwiftUI

struct DetailBanner: View {
    @EnvironmentObject var m: MessageProvider
    @EnvironmentObject var b: BannerProvider

    var body: some View {
        VSplitView {
            BannerHome(banner: $b.banner)
        }
        .frame(maxWidth: .infinity)
        .onAppear(perform: onAppear)
    }
}

extension DetailBanner {
    func onAppear() {

    }
}

#Preview {
    AppPreview()
        .frame(height: 800)
        .frame(width: 800)
}
