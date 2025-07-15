import SwiftUI
import MagicCore

struct IconTopBar: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    @State var inScreen: Bool = false
    @State var device: Device = .MacBook

    @Binding var snapshotTapped: Bool
    @Binding var icon: IconModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconOpacity()
                IconScale()
                Spacer()
                BtnChangeImage()
                BtnSnapshot(snapshotTapped: $snapshotTapped)
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .labelStyle(.iconOnly)
            .background(.secondary.opacity(0.5))
            
            GroupBox {
                Backgrounds(current: $icon.backgroundId)
            }.padding()
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
