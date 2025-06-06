import OSLog
import SwiftUI

struct TabBtn: View {
    @State private var hovered: Bool = false
    @State private var isButtonTapped = false
    @State private var showTips: Bool = false

    var title: String
    var imageName: String
    var selected = false
    var onTap: () -> Void = {
        os_log("点击了button")
    }

    var body: some View {
        Label(title: {
        Text(title)}, icon: {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
        })
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
            .background(hovered || selected ? Color.gray.opacity(0.4) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 0))
            .onHover(perform: { hovering in
                withAnimation(.easeInOut) {
                    hovered = hovering
                }
            })
            .onTapGesture {
                withAnimation(.default) {
                    onTap()
                }
            }
    }
}

#Preview("App") {
    AppPreview()
}

#Preview("App-Big Screen") {
    RootView {
        ContentView()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
