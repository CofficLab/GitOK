import SwiftUI
import MagicAll
import MagicCore
import MagicUI

/**
 设备选择器组件
 独立的设备选择下拉菜单，支持切换不同设备类型
 */
struct DeviceSelector: View {
    @EnvironmentObject var b: BannerProvider
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            // 设备选择下拉菜单
            Menu {
                ForEach([MagicDevice.iMac, MagicDevice.MacBook, MagicDevice.iPhoneBig, MagicDevice.iPhoneSmall, MagicDevice.iPad_mini], id: \.self) { device in
                    Button(action: {
                        b.setSelectedDevice(device)
                        // 切换设备时重置缩放
                        scale = 1.0
                        lastScale = 1.0
                    }) {
                        HStack {
//                            Image(systemName: device.systemImageName)
                            Text(device.description)
                        }
                    }
                }
            } label: {
                HStack {
//                    Image(systemName: b.selectedDevice.systemImageName)
                    Text(b.selectedDevice.description)
                }
            }
            .pickerStyle(MenuPickerStyle())

            Spacer()

            // 显示当前设备尺寸
            HStack(spacing: 4) {
//                Image(systemName: b.selectedDevice.systemImageName)
//                    .foregroundColor(.secondary)
                Text("\(Int(b.selectedDevice.width)) × \(Int(b.selectedDevice.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)
        }
    }
}

#Preview("App - Small Screen") {
    ContentLayout()
        .hideSidebar()
        .hideTabPicker()
        .hideProjectActions()
        .inRootView()
        .frame(width: 800)
        .frame(height: 600)
}

#Preview("App - Big Screen") {
    ContentLayout()
        .hideSidebar()
        .hideProjectActions()
        .hideTabPicker()
        .inRootView()
        .frame(width: 800)
        .frame(height: 1000)
}
