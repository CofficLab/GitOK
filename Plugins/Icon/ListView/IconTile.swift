import MagicCore
import SwiftUI

struct IconTile: View {
    var icon: IconData

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .padding(4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)

                Text(icon.title).font(.title3)
                Spacer()
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(IconPlugin.label)
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
