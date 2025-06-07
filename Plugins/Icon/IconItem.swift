import SwiftUI

struct IconItem: View {
    @EnvironmentObject var app: AppProvider

    @State var image = Image("icon")

    var selected = false

    var iconId: Int

    var body: some View {
        image
            .resizable()
            .frame(height: 80)
            .frame(width: 80)
            .background(selected ? Color.brown.opacity(0.1) : Color.clear)
            .onAppear {
                DispatchQueue.global().async {
                    let i = IconPng.getThumbnial(iconId)
                    DispatchQueue.main.async {
                        self.image = i
                    }
                }
            }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
//            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
