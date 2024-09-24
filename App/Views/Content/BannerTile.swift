import SwiftUI

struct BannerTile: View {
    var banner: BannerModel
    
    var body: some View {
        Text(banner.title)
    }}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
