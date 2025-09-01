import SwiftUI

struct BannerTopBar: View {
    @State var device: Device = .MacBook

    @Binding var snapshotTapped: Bool
    @Binding var banner: BannerData
    @Binding var showBorder: Bool

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

                Spacer()

                TabBtn(
                    title: "边框",
                    imageName: "square.dashed",
                    selected: showBorder,
                    onTap: {
                        self.showBorder.toggle()
                    }
                )

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

            GroupBox {
                Backgrounds(current: $banner.backgroundId)
            }.padding()
        }
    }
}

#Preview("BannerHome") {
    struct PreviewWrapper: View {
        @State var previewBanner = BannerData(
            title: "制作海报",
            subTitle: "简单又快捷",
            features: [
                "无广告",
                "好软件",
                "无弹窗",
                "无会员",
            ],
            path: "",
            project: Project.null
        )

        var body: some View {
            RootView {
                BannerEditor(banner: $previewBanner)
            }
            .frame(width: 500)
            .frame(height: 500)
        }
    }

    return PreviewWrapper()
}

#Preview("APP") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 500)
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
