import SwiftUI

struct Badge: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.system(size: 80))
            .padding(40)
            .background(BackgroundView.type3)
            .cornerRadius(48)
    }
}

#Preview("APP") {
    AppPreview().frame(height: 800)
}
