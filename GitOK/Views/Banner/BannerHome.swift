import SwiftUI

struct BannerHome: View {
    @EnvironmentObject var app: AppManager

    @Binding var banner: BannerModel?
    @State var snapshotTapped: Bool = false
    @State var backgroundId: String = "3"
    @State var inScreen: Bool = false
    @State var device: Device = .MacBook

    var body: some View {
        GeometryReader { geo in
            if let banner = banner {
                HStack {
                    BannerMaker(
                        snapshotTapped: $snapshotTapped,
                        onMessage: { message in
                            app.setMessage(message)
                        },
                        imageURL: banner.imageURL,
                        backgroundId: banner.backgroundId,
                        device: banner.getDevice(),
                        title: banner.title,
                        subTitle: banner.subTitle,
                        badges: banner.features,
                        inScreen: banner.inScreen
                    )

                    VStack {
                        Spacer()
                        BannerFields(banner: banner)

                        GroupBox {
                            Backgrounds(current: $backgroundId)
                        }
                    }
                    .padding(.trailing, 10)
                    .frame(width: geo.size.width * 0.3)
                }.padding()
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Picker("设备", selection: $device) {
                    Text("iMac").tag(Device.iMac)
                    Text("MacBook").tag(Device.MacBook)
                    Text("iPhoneBig").tag(Device.iPhoneBig)
                    Text("iPhoneSmall").tag(Device.iPhoneSmall)
                    Text("iPad").tag(Device.iPad)
                }
                .onAppear {
                    self.device = banner?.getDevice() ?? .MacBook
                }
                .onChange(of: device) {
                    banner?.device = device.rawValue
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Toggle(isOn: $inScreen, label: {
                    Text("显示边框")
                })
                .onAppear {
                    self.inScreen = banner?.inScreen ?? false
                }
                .onChange(of: inScreen) {
                    banner?.inScreen = inScreen
                }
            }

            ToolbarItem(placement: .primaryAction, content: {
                Button("截图", action: {
                    self.snapshotTapped = true
                })
            })
        })
        .onChange(of: backgroundId) {
            if let banner = banner {
                banner.backgroundId = backgroundId
            }
        }
    }
}

#Preview("APP") {
    AppPreview()
        .frame(width: 800)
        .frame(height: 800)
}
