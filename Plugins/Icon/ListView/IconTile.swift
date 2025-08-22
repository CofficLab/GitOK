import SwiftUI

struct IconTile: View {
    var icon: IconModel

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

            HStack {
                Text("图标ID: \(icon.iconId)").font(.caption).opacity(0.5)
                Spacer()
            }

            HStack {
                Text("背景ID: \(icon.backgroundId)").font(.caption).opacity(0.5)
                Spacer()
            }
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
