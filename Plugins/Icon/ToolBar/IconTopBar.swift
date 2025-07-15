import SwiftUI
import MagicCore

struct IconTopBar: View {
    @EnvironmentObject var m: MagicMessageProvider
    @EnvironmentObject var i: IconProvider

    @State var inScreen: Bool = false
    @State var device: Device = .MacBook

    @State var icon: IconModel?

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
                Backgrounds(current: Binding(
                    get: { self.icon?.backgroundId ?? "1" },
                    set: { newId in
                        self.icon?.backgroundId = newId
                        try? self.icon?.updateBackgroundId(newId)
                    }
                ))
            }.padding()
        }
        .onAppear {
            self.icon = try? i.getIcon()
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
