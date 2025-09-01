import MagicCore
import OSLog
import SwiftUI

struct Devices: View {
    @EnvironmentObject var bannerProvider: BannerProvider

    @State private var current: String = ""
    @State private var selection: Device? = nil

    var body: some View {
        Picker("", selection: $selection) {
            Text("iMac").tag(Device.iMac)
            Text("MacBook").tag(Device.MacBook)
            Text("iPhoneBig").tag(Device.iPhoneBig)
            Text("iPhoneSmall").tag(Device.iPhoneSmall)
            Text("iPad").tag(Device.iPad)
        }
        .frame(width: 120)
        .onAppear {
            self.selection = bannerProvider.banner.getDevice()
        }
        .onChange(of: selection) {
            try? self.bannerProvider.banner.updateDevice(selection?.rawValue ?? "")
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideProjectActions()
            .setInitialTab(BannerPlugin.label)
            .hideTabPicker()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
