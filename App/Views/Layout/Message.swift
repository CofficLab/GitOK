import SwiftUI

struct Message: View {
    @EnvironmentObject var m: MessageProvider

    var body: some View {
        if !m.message.isEmpty {
            VStack(alignment: .leading) {
                Text(m.message)
                    .font(.title)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .foregroundStyle(.white)
            }
            .background(BackgroundGroup(for: .yellow2blue_tl2br))
            .cornerRadius(8)
            .shadow(color: Color.gray, radius: 12, x: 2, y: 2)
        }
    }
}

#Preview("App") {
    RootView {
        Content()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App-2") {
    RootView {
        Content()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
