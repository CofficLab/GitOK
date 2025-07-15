import MagicCore
import SwiftUI

struct IconTopBar: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconOpacity()
                IconScale()
                Spacer()
                BtnChangeImage()
                BtnSnapshot()
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .labelStyle(.iconOnly)
            .background(.secondary.opacity(0.5))

            GroupBox {
                IconBgs()
            }.padding()

            GroupBox {
                IconAssetList()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
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
