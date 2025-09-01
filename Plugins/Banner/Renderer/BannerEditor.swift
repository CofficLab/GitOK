import MagicCore
import SwiftUI

/**
     Banner编辑器
     提供Banner的可视化编辑和预览功能，支持缩放、截图等操作。
     直接从BannerProvider获取数据，通过事件通知处理截图操作。

     ## 功能特性
     - 实时编辑预览
     - 手势缩放支持
     - 事件驱动的截图功能
     - 自适应布局调整
     - 异步加载优化
 **/
struct BannerEditor: View {
    @EnvironmentObject var b: BannerProvider
    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State var showBorder: Bool = false
    @State var visible = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var selectedDevice: Device = .iMac

    @MainActor private var imageSize: String {
        "\(MagicImage.getViewWidth(content)) X \(MagicImage.getViewHeigth(content))"
    }

    var body: some View {
        VStack {
            // 设备选择器
            deviceSelector
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))

            bodyBanner
        }
    }

    var bodyBanner: some View {
        // 异步加载banner，加快响应速度
        ZStack {
            if !visible {
                ProgressView()
                    .onAppear {
                        visible = true
                    }
            }

            if visible {
                viewBody
            }
        }
        .onBannerSnapshot {
            handleSnapshot()
        }
    }

    var viewBody: some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width)
                .frame(height: geo.size.height)
                .alignmentGuide(HorizontalAlignment.center) { _ in geo.size.width / 2 }
                .alignmentGuide(VerticalAlignment.center) { _ in geo.size.height / 2 }
                .scaleEffect(calculateOptimalScale(geometry: geo) * scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
        }
        .padding()
    }

    var imageBody: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                MagicImage.makeImage(content)
                    .resizable()
                    .scaledToFit()
                    .padding(.all, 20)
                Spacer()
            }
            Spacer()
        }
    }

    private var content: some View {
        BannerLayout(device: selectedDevice)
            .frame(width: selectedDevice.width)
            .frame(height: selectedDevice.height)
            .environmentObject(BannerProvider.shared)
    }

    private var deviceSelector: some View {
        HStack(spacing: 16) {
            // 设备选择下拉菜单
            Picker("设备", selection: $selectedDevice) {
                ForEach([Device.iMac, Device.MacBook, Device.iPhoneBig, Device.iPhoneSmall, Device.iPad], id: \.self) { device in
                    HStack {
                        Image(systemName: device.systemImageName)
                        Text(device.description)
                    }
                    .tag(device)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedDevice) {
                // 切换设备时重置缩放
                scale = 1.0
                lastScale = 1.0
            }

            Spacer()

            // 显示当前设备尺寸
            HStack(spacing: 4) {
                Image(systemName: selectedDevice.systemImageName)
                    .foregroundColor(.secondary)
                Text("\(Int(selectedDevice.width)) × \(Int(selectedDevice.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)
        }
    }

    /// 计算最优缩放比例 - 恢复原版本的简单高效逻辑
    /// 根据当前选中设备和容器大小计算最佳显示比例
    private func calculateOptimalScale(geometry: GeometryProxy) -> CGFloat {
        // 计算可用空间，为设备选择器预留空间
        let availableWidth = geometry.size.width
        let availableHeight = geometry.size.height - 45 // 为下拉选择器预留更少空间

        // 直接使用当前选中设备的尺寸进行计算
        let widthScale = availableWidth / selectedDevice.width
        let heightScale = availableHeight / selectedDevice.height

        // 选择较小的比例确保完整显示，这就是原版本的逻辑！
        return min(widthScale, heightScale)
    }

    /// 处理截图事件
    private func handleSnapshot() {
        guard g.project != nil else {
            m.error("没有选中的项目")
            return
        }

        let result = MagicImage.snapshot(content)

        m.success(result)
    }

    private func getTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter.string(from: Date())
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(BannerPlugin.label)
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .hideSidebar()
            .hideTabPicker()
            .setInitialTab(BannerPlugin.label)
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
