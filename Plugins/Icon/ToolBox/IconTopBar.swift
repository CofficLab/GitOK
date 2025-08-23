import MagicCore
import SwiftUI

struct IconTopBar: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                BtnChangeImage()
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .labelStyle(.iconOnly)
            .background(.secondary.opacity(0.5))

            GroupBox {
                IconBgs()
            }.padding()

            GroupBox {
                IconBoxView()
            }
            .padding(.horizontal)
            .padding(.bottom)
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
    .frame(height: 800)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout().setInitialTab("Icon")
            .hideSidebar()
    }
    .frame(width: 1200)
    .frame(height: 1200)
}
