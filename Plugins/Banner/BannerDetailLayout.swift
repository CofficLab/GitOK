import MagicCore
import OSLog
import SwiftUI

/**
     Banner详情布局视图
     主要的Banner编辑界面，包含顶部的Banner标签页和主要的编辑区域。
 **/
struct BannerDetailLayout: View {
    static var shared = BannerDetailLayout()

    @EnvironmentObject var g: DataProvider
    @EnvironmentObject var m: MagicMessageProvider

    @State private var selection: BannerData?
    @State private var selectedDevice: Device = .iMac
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var selectedTemplate: any BannerTemplateProtocol = ClassicBannerTemplate()

    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                VStack(spacing: 0) {
                    BannerTabsBar(selection: $selection)
                        .background(.gray.opacity(0.1))
                    
                    Divider()
                    
                    // 设备选择器
                    DeviceSelector(
                        selectedDevice: $selectedDevice,
                        scale: $scale,
                        lastScale: $lastScale
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor))
                    
                    Divider()

                    // 模板提供的预览视图
                    selectedTemplate.createPreviewView(device: selectedDevice)
                        .frame(maxHeight: .infinity)
                }

                VStack(spacing: 0) {
                    // 模板选择器
                    TemplateSelector(selectedTemplate: $selectedTemplate)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                    
                    // 模板提供的修改器视图
                    selectedTemplate.createModifierView()
                        .frame(maxHeight: .infinity)
                    
                    // 下载按钮区域
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.bottom, 16)
                        
                        BannerDownloadButtons(template: selectedTemplate)
                            .environmentObject(BannerProvider.shared)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.5)
                .frame(maxHeight: .infinity)
            }
            .environmentObject(BannerProvider.shared)
        }
    }
}

#Preview("App - Small Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideSidebar()
            .hideProjectActions()
    }
    .frame(width: 800)
    .frame(height: 600)
}

#Preview("App - Big Screen") {
    RootView {
        ContentLayout()
            .setInitialTab(BannerPlugin.label)
            .hideProjectActions()
            .hideTabPicker()
            .hideSidebar()
    }
    .frame(width: 800)
    .frame(height: 1000)
}
