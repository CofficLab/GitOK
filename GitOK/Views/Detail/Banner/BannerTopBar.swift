import SwiftUI

struct BannerTopBar: View {
    @State var tab: ActionTab = .Git
    @State var inScreen: Bool = false
    @State var device: Device = .MacBook

    @Binding var snapshotTapped: Bool
    @Binding var banner: BannerModel

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Row 1

            HStack(spacing: 0) {
                Picker("", selection: $device) {
                    Text("iMac").tag(Device.iMac)
                    Text("MacBook").tag(Device.MacBook)
                    Text("iPhoneBig").tag(Device.iPhoneBig)
                    Text("iPhoneSmall").tag(Device.iPhoneSmall)
                    Text("iPad").tag(Device.iPad)
                }
                .frame(width: 120)
                .onAppear {
                    self.device = self.banner.getDevice()
                }
                .onChange(of: device) {
                    self.banner.device = device.rawValue
                }

                Toggle(isOn: $inScreen, label: {
                    Text("显示边框")
                })
                .padding()
                .onAppear {
                    self.inScreen = self.banner.inScreen
                }
                .onChange(of: inScreen) {
                    self.banner.inScreen = inScreen
                }

                Spacer()

                // MARK: Change Image
                Button("换图") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        let ext = url.pathExtension
                        let storeURL = AppConfig.imagesDir.appendingPathComponent("\(TimeHelper.getTimeString()).\(ext)")
                        do {
                            try FileManager.default.copyItem(at: url, to: storeURL)
                            self.banner.imageURL = storeURL
                        } catch let e {
                            print(e)
                        }
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
            
            // MARK: Row2
            
            Backgrounds(current: $banner.backgroundId)
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
        .frame(height: 800)
}
