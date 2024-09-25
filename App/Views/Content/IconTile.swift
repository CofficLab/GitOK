import SwiftUI

struct IconTile: View {
    var icon: IconModel

    var body: some View {
        Text(icon.title)
    }
}

#Preview {
    AppPreview()
        .frame(width: 800)
        .frame(height: 500)
}
