import SwiftUI

struct Badges: View {
    var device: Device
    var badges: [String]
    
    var body: some View {
        ZStack {
            if device == .iPhoneBig
                || device == .iPhoneSmall || device == .iPad {
                HStack(spacing: 50) {
                    ForEach(badges, id: \.self) { badge in
                        Badge(title: badge)
                    }
                }
            } else {
                LazyHGrid(rows: [
                    GridItem(.flexible(minimum: 260, maximum: 300)),
                    GridItem(.flexible(minimum: 260, maximum: 300)),
                ], spacing: 50) {
                    ForEach(badges, id: \.self) { badge in
                        Badge(title: badge)
                    }
                }
            }
        }
    }
}

#Preview {
    RootView {
        Content()
    }
}
