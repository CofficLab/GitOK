import SwiftUI

struct Message: View {
    @EnvironmentObject var app: AppProvider

    var body: some View {
        if !app.message.isEmpty {
            VStack(alignment: .leading) {
                Text(app.message)
                    .font(.title)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .foregroundStyle(.white)
            }
            .background(BackgroundGroup.yellow2blue_tl2br)
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
