import SwiftUI

struct BannerBar: View {
    @State var tab: ActionTab = .Git
    @State var inScreen: Bool = false
    @State var device: Device = .MacBook
    
    @Binding var snapshotTapped: Bool
    @Binding var banner: BannerModel?
    
    var body: some View {
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
                self.device = self.banner?.getDevice() ?? .MacBook
            }
            .onChange(of: device) {
                self.banner?.device = device.rawValue
            }
            
            Toggle(isOn: $inScreen, label: {
                Text("显示边框")
            })
            .padding()
            .onAppear {
                self.inScreen = ((self.banner?.inScreen) != nil)
            }
            .onChange(of: inScreen) {
                self.banner?.inScreen = inScreen
            }
            
            Spacer()
            
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
    }
}

#Preview {
    AppPreview()
}
