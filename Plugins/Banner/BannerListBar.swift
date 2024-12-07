import SwiftUI

struct BannerListBar: View {
    var body: some View {
        HStack(spacing: 0) {
            BannerBtnAdd()
        }
        .frame(height: 25)
        .labelStyle(.iconOnly)
    }
}
