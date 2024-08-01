import SwiftUI

struct BannerOpacity: View {
    @Binding var banner: BannerModel
    
    var body: some View {
        VStack {
            Slider(value: $banner.opacity, in: 0 ... 1)
                .padding()
        }
        .padding()
    }
}

#Preview {
    RootView {
        Content()
    }
}
