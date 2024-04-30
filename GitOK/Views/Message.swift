import SwiftUI

struct Message: View {
    @EnvironmentObject var app: AppManager

    var body: some View {
        if !app.message.isEmpty {
            VStack(alignment: .leading) {
                Text(app.message)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(Color.blue.opacity(0.2))
                    .foregroundStyle(.white)
                    .shadow(color: Color.green, radius: 12, x: 0, y: 2)
            }
            .background(BackgroundView.type1.opacity(0.95))
            .cornerRadius(8)
            .shadow(color: Color.gray, radius: 12, x: 2, y: 2)
        }
    }
}

#Preview {
    RootView {
        Content()
    }
}
