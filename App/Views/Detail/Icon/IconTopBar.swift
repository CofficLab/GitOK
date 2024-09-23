import SwiftUI

struct IconTopBar: View {
    @State var tab: ActionTab = .Git
    @State var inScreen: Bool = false
    @State var device: Device = .MacBook

    @Binding var snapshotTapped: Bool
    @Binding var icon: IconModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconOpacity(icon: $icon)
                IconScale(icon: $icon)
                Spacer()
                Button("换图") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        self.icon.updateImageURL(url)
                    }
                }
                TabBtn(
                    title: "截图",
                    imageName: "camera.aperture",
                    selected: false,
                    onTap: {
                        self.snapshotTapped = true
                    }
                )
            }
            .frame(height: 25)
            .frame(maxWidth: .infinity)
            .labelStyle(.iconOnly)
            .background(.secondary.opacity(0.5))
            
            Backgrounds(current: $icon.backgroundId)
        }
    }
}

#Preview("BannerHome") {
    RootView {
        BannerHome(banner: Binding.constant(BannerModel(
            title: "精彩标题",
            subTitle: "精彩小标题",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: ""
        )))
    }
    .frame(width: 500)
    .frame(height: 400)
}

#Preview("App") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
